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
		
		if ([givenURL query])
			arguments = IRQueryParametersFromString([givenURL query]);
		
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
