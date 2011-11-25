//
//  IRWebAPIEngine+ExternalTransforms.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/14/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine+ExternalTransforms.h"

@interface IRWebAPIEngine (ExternalTransforms_KnownPrivate)

- (NSDictionary *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil;

- (NSDictionary *) requestContextByTransformingContext:(NSDictionary *)inContext forMethodNamed:(NSString *)inMethodName;

- (NSURLRequest *) requestWithContext:(NSDictionary *)inContext;

@end

@implementation IRWebAPIEngine (ExternalTransforms)

- (NSURLRequest *) transformedRequestWithRequest:(NSURLRequest *)aRequest usingMethodName:(NSString *)aName {

	NSDictionary *baseContext = [self baseRequestContextWithMethodName:aName arguments:nil options:nil];
	
	NSURL *baseURL = [baseContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
	NSDictionary *headerFields = [baseContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields];
	NSDictionary *arguments = [baseContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
	NSData *httpBody = [baseContext objectForKey:kIRWebAPIEngineRequestHTTPBody];
	NSString *httpMethod = [baseContext objectForKey:kIRWebAPIEngineRequestHTTPMethod];
	IRWebAPIResponseParser responseParser = [baseContext objectForKey:kIRWebAPIEngineParser];
	
	if ([[aRequest allHTTPHeaderFields] count])
		headerFields = [aRequest allHTTPHeaderFields];
		
	if ([aRequest HTTPBody])
		httpBody = [aRequest HTTPBody];
	
	if ([aRequest URL]) {
	
		NSURL *givenURL = [aRequest URL];
		
		NSString *baseURLString = [[NSArray arrayWithObjects:
		
			[givenURL scheme] ? [[givenURL scheme] stringByAppendingString:@"://"]: @"",
			[givenURL host] ? [givenURL host] : @"",
			[givenURL port] ? [@":" stringByAppendingString:[[givenURL port] stringValue]] : @"",
			[givenURL path] ? [givenURL path] : @"",
			//	[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
			//	[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
		
		nil] componentsJoinedByString:@""];
		
		if ([givenURL query]) {
		
				NSMutableDictionary *mutableArguments = [[arguments mutableCopy] autorelease];
				arguments = mutableArguments;
		
				NSString *query = [givenURL query];
				NSRange queryFullRange = (NSRange) {0, [query length] };
				
				NSString *queryPairPattern = @"([^=\\?\\&]+)=([^=\\?\\&]+)?";
				NSRegularExpression *queryPairExpression = [NSRegularExpression regularExpressionWithPattern:queryPairPattern options:0 error:nil];
				
				//	([^=\?\&]+)=([^=\?\&]+)?(?=&)

				[queryPairExpression enumerateMatchesInString:query options:0 range:queryFullRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
				
					__block NSString *currentArgumentName = nil;
					__block NSString *currentArgumentValue = nil;
					
					NSUInteger numberOfRanges = result.numberOfRanges;
					for (NSUInteger i = 0; i < numberOfRanges; i++) {
						
						NSRange substringRange = [result rangeAtIndex:i];
						NSString *substring = [query substringWithRange:substringRange];
						
						if (i == 1)
							currentArgumentName = substring;
						else if (i == 2)
							currentArgumentValue = substring;
					
					}
					
					if (currentArgumentValue)
						[mutableArguments setObject:currentArgumentValue forKey:currentArgumentName];
					else
						[mutableArguments setObject:@"" forKey:currentArgumentName];
					
				}];
				
		}
		
		baseURL = [NSURL URLWithString:baseURLString];
	
	}
	
	NSDictionary *inferredContext = [NSDictionary dictionaryWithObjectsAndKeys:
	
		baseURL, kIRWebAPIEngineRequestHTTPBaseURL,
		headerFields, kIRWebAPIEngineRequestHTTPHeaderFields,
		arguments, kIRWebAPIEngineRequestHTTPQueryParameters,
		httpBody, kIRWebAPIEngineRequestHTTPBody,
		httpMethod, kIRWebAPIEngineRequestHTTPMethod,
		responseParser, kIRWebAPIEngineParser,
	
	nil];
	
	NSDictionary *transformedContext = [self requestContextByTransformingContext:inferredContext forMethodNamed:aName];
	NSURLRequest *returnedRequest = [self requestWithContext:transformedContext];
	
	return returnedRequest;

}

@end
