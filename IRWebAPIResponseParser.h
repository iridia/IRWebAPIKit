//
//  IRWebAPIResponseParser.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/20/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRWebAPIKit.h"

#ifndef IRWebAPIResponseParserSections
#define IRWebAPIResponseParserSections





#pragma mark Parsers and Parser Bridges


//	Parser blocks are supposed to be bridges to other larger, more capable Objective-C classes.
//	i.e., you are not supposed to work an entire XML parser into a block.





static inline IRWebAPIResponseParser IRWebAPIResponseDefaultParserMake () {

//	Simply tucks the returned data into a dictionary

	NSDictionary * (^defaultParser) (NSData *) = ^ NSDictionary * (NSData *inData) {
	
		return [NSDictionary dictionaryWithObjectsAndKeys:
		
			inData, @"response",
			[[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease], @"responseText",
			
		nil];
	
	};

	return defaultParser;

}





static inline IRWebAPIResponseParser IRWebAPIResponseQueryResponseParserMake () {

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
	
	return queryResponseParser;

}





static inline IRWebAPIResponseParser IRWebAPIResponseDefaultJSONParserMake () {

	NSDictionary * (^defaultJSONParser) (NSData *) = ^ NSDictionary * (NSData *inData) {

		Class classCJSONDeserializer = NSClassFromString(@"CJSONDeserializer");
		
		if (!classCJSONDeserializer)
		return nil;

		if (![(NSObject *)classCJSONDeserializer respondsToSelector:@selector(deserializer)])
		return nil;
				
		id deserializer = [classCJSONDeserializer performSelector:@selector(deserializer)];

		if (!deserializer)
		return nil;
		
		SEL selDeserialize = @selector(deserialize:error:);
		
		if (![deserializer respondsToSelector:selDeserialize])
		return nil;
		
		id incomingObject;

		NSError *error = nil;
		NSError **errorPointer = &error;
		
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[deserializer methodSignatureForSelector:selDeserialize]];

		[invocation setTarget:deserializer];
		[invocation setSelector:selDeserialize];
		[invocation setArgument:&inData atIndex:2]; 
		[invocation setArgument:&errorPointer atIndex:3];

		[invocation invoke];
		[invocation getReturnValue:&incomingObject];
		
		if (!incomingObject)
		return nil;

		if ([incomingObject isKindOfClass:[NSDictionary class]])
		return (NSDictionary *)incomingObject;
		
		return [NSDictionary dictionaryWithObject:incomingObject forKey:@"response"];
	
	};
	
	return defaultJSONParser;
	
}





#endif




