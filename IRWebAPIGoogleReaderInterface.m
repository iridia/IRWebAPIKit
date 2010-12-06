//
//  IRWebAPIGoogleReaderInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIGoogleReaderInterface.h"


@implementation IRWebAPIGoogleReaderInterface

- (id) init {

	IRWebAPIContext *googleReaderContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.google.com"]] autorelease];

	IRWebAPIEngine *googleReaderEngine = [[[IRWebAPIEngine alloc] initWithContext:googleReaderContext] autorelease];
	
	googleReaderEngine.parser = IRWebAPIResponseDefaultJSONParserMake();

	IRWebAPIAuthenticator *googleReaderAuthenticator = [[IRWebAPIGoogleReaderAuthenticator alloc] initWithEngine:googleReaderEngine];
		
	self = [self initWithEngine:googleReaderEngine authenticator:googleReaderAuthenticator];

	if (!self) return nil;

	return self;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	[self.authenticator authenticateCredentials:inCredentials onSuccess:successHandler onFailure:failureHandler];

}

@end





//		googleReaderEngine = [[IRWebAPIEngine alloc] initWithContext:[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.google.com"]]];
//		
//		googleReaderEngine.parser = IRWebAPIResponseDefaultJSONParserMake();
//		
//		IRWebAPIAuthenticator *googleReaderAuthenticator = [[IRWebAPIGoogleReaderAuthenticator alloc] initWithEngine:googleReaderEngine];
//		
//		[googleReaderAuthenticator authenticateCredentials:[[[IRWebAPICredentials alloc] initWithIdentifier:MILK_DEVELOPMENT_GOOGLE_USER_IDENTIFIER qualifier:MILK_DEVELOPMENT_GOOGLE_USER_QUALIFIER] autorelease] onSuccess:^(IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry) {
//			
//			[googleReaderEngine fireAPIRequestNamed:@"reader/api/0/user-info" withArguments:nil onSuccess: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) { 
//			
//				NSLog(@"reader/api/0/user-info: %@", inResponseOrNil);
//			
//			} onFailure:nil];
//			
//		 } onFailure:nil];




