//
//  IRWebAPIResponseParser.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/29/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIResponseParser.h"





IRWebAPIResponseParser IRWebAPIResponseDefaultParserMake () {

//	Simply tucks the returned data into a dictionary

	NSDictionary * (^defaultParser) (NSData *) = ^ NSDictionary * (NSData *inData) {
	
		return [NSDictionary dictionaryWithObjectsAndKeys:
		
			inData, @"response",
			[[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease], @"responseText",
			
		nil];
	
	};

	return [[defaultParser copy] autorelease];

}





IRWebAPIResponseParser IRWebAPIResponseQueryResponseParserMake () {

//	Parses UTF8 String Data Like:	
//	
//	Key=URL_Encoded_Value
//	Another_Key=Another_Encoded_Value
	
	NSDictionary * (^queryResponseParser) (NSData *) = ^ NSDictionary * (NSData *inData) {
	
		NSString *responseString = [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease];
		
		NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"([^=&\n\r]+)=([^=&\n\r]+)[\n\r&]?" options:NSRegularExpressionCaseInsensitive error:nil];
		
		NSMutableDictionary *returnedResponse = [NSMutableDictionary dictionary];
		
		@try {
		
			[expression enumerateMatchesInString:responseString options:0 range:NSMakeRange(0, [responseString length]) usingBlock: ^ (NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
			
				[returnedResponse setObject:[responseString substringWithRange:[result rangeAtIndex:2]] forKey:[responseString substringWithRange:[result rangeAtIndex:1]]];
			
			}];
		
		} @catch (NSException * e) {
			
			NSLog(@"IRWebAPIResponseQueryResponseParser encountered an exception while parsing response.  Returning empty dictionary.");
			
			return [NSDictionary dictionary];
			
		}

		return returnedResponse;
	
	};
	
	return [[queryResponseParser copy] autorelease];

}





IRWebAPIResponseParser IRWebAPIResponseDefaultJSONParserMake () {

	static id parserInstance = nil;
	static IRWebAPIResponseParser parserBlock = nil;
	
	if (parserBlock)
		return parserBlock;
	
	NSDictionary * (^dictionarize)(id<NSObject>) = ^ (id<NSObject> incomingObject) {

		if (!incomingObject)
			return (NSDictionary *)nil;

		if (![incomingObject isKindOfClass:[NSDictionary class]])
			return [NSDictionary dictionaryWithObject:incomingObject forKey:@"response"];
		
		return (NSDictionary *)incomingObject;

	};
	
	Class classJSONKit = NSClassFromString(@"JSONDecoder");
	if (classJSONKit) {
	
		parserInstance = [classJSONKit performSelector:@selector(decoder)];
		[parserInstance retain];
	
		parserBlock = (IRWebAPIResponseParser)[[^ (NSData *incomingData) {
			return dictionarize([parserInstance performSelector:@selector(objectWithData:) withObject:incomingData]);
		} copy] autorelease];
		
		return parserBlock;
		
	}
	
	Class classTouchJSON = NSClassFromString(@"CJSONDeserializer");
	if (classTouchJSON) {
		
		parserInstance = [classTouchJSON performSelector:@selector(deserializer)];
		[parserInstance retain];
		
		parserBlock = (IRWebAPIResponseParser)[[^ (NSData *incomingData) {
			
			SEL selDeserialize = @selector(deserialize:error:);
			id incomingObject;

			NSError *error = nil;
			NSError **errorPointer = &error;
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[parserInstance methodSignatureForSelector:selDeserialize]];
			
			[invocation setTarget:parserInstance];
			[invocation setSelector:selDeserialize];
			[invocation setArgument:&incomingData atIndex:2]; 
			[invocation setArgument:&errorPointer atIndex:3];
			[invocation invoke];
			[invocation getReturnValue:&incomingObject];
			
			return dictionarize(incomingObject);
			
		} copy] autorelease];
		
		return parserBlock;
	
	}
	
	return IRWebAPIResponseDefaultParserMake();
	
}

IRWebAPIResponseParser IRWebAPIResponseDefaultXMLParserMake () {

	static IRWebAPIResponseParser parserBlock = nil;
	
	if (parserBlock)
		return parserBlock;
	
	Class classTouchXMLDocument = NSClassFromString(@"CXHTMLDocument");
	if (classTouchXMLDocument) {
	
		parserBlock = (IRWebAPIResponseParser)[[^ (NSData *incomingData) {
	
			SEL selInstantiate = @selector(initWithXHTMLData:encoding:options:error:);
			id incomingObject = nil;
			
			NSError *error = nil;
			NSError **errorPointer = &error;
			
			id parserInstance = [classTouchXMLDocument performSelector:@selector(alloc)];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[parserInstance methodSignatureForSelector:selInstantiate]];
			
			NSStringEncoding stringEncoding = NSUTF8StringEncoding;
			NSUInteger options = 0;
			
			[invocation setTarget:parserInstance];
			[invocation setSelector:selInstantiate];
			[invocation setArgument:&incomingData atIndex:2]; 
			[invocation setArgument:&stringEncoding atIndex:3];
			[invocation setArgument:&options atIndex:4]; 
			[invocation setArgument:&errorPointer atIndex:5]; 
			[invocation invoke];
			[invocation getReturnValue:&incomingObject];
	
		} copy] autorelease];
		
		return parserBlock;
		
	}
	
	return IRWebAPIResponseDefaultParserMake();

}
