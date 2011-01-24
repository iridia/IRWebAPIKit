//
//  IRWebAPIGoogleReaderAuthenticator.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"
#import "IRWebAPIGoogleReaderAuthenticator.h"

@interface IRWebAPIGoogleReaderAuthenticator ()

@property (nonatomic, retain, readwrite) NSString *authToken;

@end


@implementation IRWebAPIGoogleReaderAuthenticator

@synthesize authToken;

- (void) createTransformerBlocks {

	self.globalRequestPreTransformerBlock = [[^ (NSDictionary *inOriginalContext) {
	
		if (!self.currentCredentials) return inOriginalContext;
		if (!self.authToken) return inOriginalContext;
		
		NSMutableDictionary *transformedContext = [[inOriginalContext mutableCopy] autorelease];
		
		NSMutableDictionary *headerFields = [transformedContext valueForKey:kIRWebAPIEngineRequestHTTPHeaderFields];
		
		if (![headerFields isEqual:[NSNull null]]) {
		
			if (![headerFields isKindOfClass:[NSMutableDictionary class]]) {

				headerFields = [[headerFields mutableCopy] autorelease];
				[transformedContext setObject:headerFields forKey:kIRWebAPIEngineRequestHTTPHeaderFields];
				
			}
		
			[headerFields setObject:[NSString stringWithFormat:@"GoogleLogin auth=%@", self.authToken] forKey:@"Authorization"];
		
		}
		
		return (NSDictionary *)transformedContext;
	
	} copy] retain];

	self.globalResponsePreTransformerBlock = [[^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
	
	//	FIXME: Probably add code to handle possible authentication failure and trigger synchronous, blocking reauthentication?
	
		return inParsedResponse;
	
	} copy] retain];

}

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine {

	[self disassociateEngine];
		
	self.authToken = nil;
	self.engine = inEngine;
	
	[super associateWithEngine:inEngine];
	
}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	[self.engine fireAPIRequestNamed:@"accounts/ClientLogin" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

//		Does not quite work
//		@"HOSTED_OR_GOOGLE", @"accountType",

		@"reader", @"service",		
		inCredentials.identifier, @"Email",
		inCredentials.qualifier, @"Passwd",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIResponseQueryResponseParserMake(), kIRWebAPIEngineParser,
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
		[NSDictionary dictionaryWithObjectsAndKeys:@"application/x-www-form-urlencoded", @"Content-type", nil], kIRWebAPIEngineRequestHTTPHeaderFields,
	
	nil] validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if ([[inResponseOrNil valueForKey:@"Auth"] isEqual:[NSNull null]]) return NO;
		return YES;
	
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		self.authToken = [inResponseOrNil valueForKey:@"Auth"];
		self.currentCredentials = inCredentials;
		
		if (successHandler)
		successHandler(self, YES, outShouldRetry);
	
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSLog(@"Authentication Failure: %@", inResponseOrNil);
		
		*outShouldRetry = NO;

		if (failureHandler)
		failureHandler(self, NO, outShouldRetry);
			
	}];

}

@end
