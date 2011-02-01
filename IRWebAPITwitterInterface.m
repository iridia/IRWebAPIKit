//
//  IRWebAPITwitterInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"

@implementation IRWebAPITwitterInterface

@synthesize defaultBatchSize;
@synthesize consumerKey, consumerSecret;

- (id) init {

	IRWebAPIContext *twitterContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/"]] autorelease];

	IRWebAPIEngine *twitterEngine = [[[IRWebAPIEngine alloc] initWithContext:twitterContext] autorelease];
	
	twitterEngine.parser = IRWebAPIResponseDefaultJSONParserMake();
	
	IRWebAPIXOAuthAuthenticator *twitterAuthenticator = [[[IRWebAPIXOAuthAuthenticator alloc] initWithEngine:twitterEngine] autorelease];
	
	self = [self initWithEngine:twitterEngine authenticator:twitterAuthenticator];

	if (!self) return nil;
	
	self.defaultBatchSize = 200;

	return self;

}

- (void) dealloc {

//	IRWebAPIInterfaceXOAuthAuthenticating
	self.consumerKey = nil;
	self.consumerSecret = nil;

	[super dealloc];

}





- (void) setConsumerKey:(NSString *)inConsumerKey {

	((IRWebAPIXOAuthAuthenticator *)(self.authenticator)).consumerKey = inConsumerKey;

}

- (NSString *) consumerKey {

	return ((IRWebAPIXOAuthAuthenticator *)(self.authenticator)).consumerKey;

}

- (void) setConsumerSecret:(NSString *)inConsumerSecret {

	((IRWebAPIXOAuthAuthenticator *)(self.authenticator)).consumerSecret = inConsumerSecret;

}

- (NSString *) consumerSecret {

	return ((IRWebAPIXOAuthAuthenticator *)(self.authenticator)).consumerSecret;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	NSLog(@"%@ %s", self, __PRETTY_FUNCTION__);
	
	NSLog(@"My authenticator , %@", self.authenticator);

	[self.authenticator authenticateCredentials:inCredentials onSuccess: ^ (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry) {
	
		NSLog(@"authentication is done.");
	
		if (!isAuthenticated) {
		
			*inShouldRetry = YES;
			return;
		
		}

		if (successHandler)
		successHandler(inAuthenticator, isAuthenticated, inShouldRetry);
	
	} onFailure: ^ (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry) {
	
		NSLog(@"Failed. %@", self);
	
		if (failureHandler)
		failureHandler(inAuthenticator, isAuthenticated, inShouldRetry);
	
	}];

}





- (void) updateStatusForCurrentUserWithContents:(NSString *)inContents userInfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/statuses/update.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		inContents, @"status",
		[NSString stringWithFormat:@"%llu", [(NSNumber *)[inUserInfo objectForKey:@"replyingStatusIdentifier"] unsignedLongLongValue]], @"in_reply_to_status_id",
		[inUserInfo objectForKey:@"latitude"], @"lat",
		[inUserInfo objectForKey:@"longitude"], @"lng",
		[inUserInfo objectForKey:@"placeIdentifier"], @"placeID",
		[inUserInfo objectForKey:@"displaysCoordinates"], @"display_coordinates",
		[NSNumber numberWithBool:YES], @"include_entities",

	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		id returnedError = [inResponseOrNil objectForKey:@"error"];
		return (BOOL)(returnedError == nil);
	
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {

		NSLog(@"statuses/update response: %@", inResponseOrNil);
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);

	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSLog(@"Failed. %@", inResponseOrNil);
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}


	


- (void) lookupCurrentUserWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/account/verify_credentials.json" withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);

	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





@end
