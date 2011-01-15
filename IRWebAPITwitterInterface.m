//
//  IRWebAPITwitterInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IRWebAPITwitterInterface.h"

@implementation IRWebAPITwitterInterface

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

	IRWebAPIXOAuthAuthenticator *authenticator = (IRWebAPIXOAuthAuthenticator *)(self.authenticator);
	authenticator.consumerKey = inConsumerKey;

}

- (NSString *) consumerKey {

	IRWebAPIXOAuthAuthenticator *authenticator = (IRWebAPIXOAuthAuthenticator *)(self.authenticator);
	return authenticator.consumerKey;

}

- (void) setConsumerSecret:(NSString *)inConsumerSecret {

	IRWebAPIXOAuthAuthenticator *authenticator = (IRWebAPIXOAuthAuthenticator *)(self.authenticator);
	authenticator.consumerSecret = inConsumerSecret;

}

- (NSString *) consumerSecret {

	IRWebAPIXOAuthAuthenticator *authenticator = (IRWebAPIXOAuthAuthenticator *)(self.authenticator);
	return authenticator.consumerSecret;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	[self.authenticator authenticateCredentials:inCredentials onSuccess:successHandler onFailure:failureHandler];

}





- (void) updateStatusForCurrentUserWithContents:(NSString *)inContents userinfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {

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

	nil] validator: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
		id returnedError = [inResponseOrNil objectForKey:@"error"];
		return (BOOL)(returnedError == nil);
	
	} successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {

		NSLog(@"statuses/update response: %@", inResponseOrNil);
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);

	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSLog(@"Failed. %@", inResponseOrNil);
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}





@end
