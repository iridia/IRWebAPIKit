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

	self.globalRequestTransformerBlock = [[^ (NSDictionary *inOriginalContext) {
	
		if (!self.currentCredentials) return inOriginalContext;
		if (!self.authToken) return inOriginalContext;
		
		NSMutableDictionary *transformedContext = [inOriginalContext mutableCopy];
		
		NSMutableDictionary *headerFields = [transformedContext valueForKey:kIRWebAPIEngineRequestHTTPHeaderFields];

		if (![headerFields isEqual:[NSNull null]])
		[headerFields setObject:[NSString stringWithFormat:@"GoogleLogin auth=%@", self.authToken] forKey:@"Authorization"];
		
		return (NSDictionary *)transformedContext;
	
	} copy] retain];

	self.globalResponseTransformerBlock = [[^ (NSDictionary *inOriginalContext) {
	
	//	FIXME: Probably add code to handle possible authentication failure and trigger synchronous, blocking reauthentication?
	
		return inOriginalContext;
	
	} copy] retain];


}

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine {

	[self disassociateEngine];

	self.authToken = nil;
	self.engine = inEngine;
	
	[self.engine.globalRequestTransformers addObject:self.globalRequestTransformerBlock];
	[self.engine.globalResponseTransformers addObject:self.globalResponseTransformerBlock];

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
	
	nil] onSuccess: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSString *probableAuthToken = [inResponseOrNil valueForKey:@"Auth"];
		if (!probableAuthToken || [probableAuthToken isEqual:[NSNull null]]) {
		
			if (failureHandler)
			failureHandler(self, NO, inShouldRetry);
			
			return;
		
		}
		
		self.authToken = probableAuthToken;
		self.currentCredentials = inCredentials;
		
		if (successHandler) successHandler(self, YES, inShouldRetry);
	
	} onFailure: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		if (failureHandler)
		failureHandler(self, NO, inShouldRetry);
	
	}];

}

@end
