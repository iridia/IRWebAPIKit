//
//  IRWebAPITwitterInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"


@implementation IRWebAPITwitterInterface

- (id) init {

	IRWebAPIContext *twitterContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/1"]] autorelease];

	IRWebAPIEngine *twitterEngine = [[[IRWebAPIEngine alloc] initWithContext:twitterContext] autorelease];
	
	twitterEngine.parser = IRWebAPIResponseDefaultJSONParserMake();
	
	IRWebAPIXOAuthAuthenticator *twitterAuthenticator = [[[IRWebAPIXOAuthAuthenticator alloc] initWithEngine:twitterEngine] autorelease];
	
	self = [self initWithEngine:twitterEngine authenticator:twitterAuthenticator];

	if (!self) return nil;

	return self;

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





- (void) updateStatusForCurrentUserWithContents:(NSString *)inContents userinfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPICallback)inSuccessCallback onFailure:(IRWebAPICallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"/statuses/update.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		inContents, @"status",

	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {

		NSLog(@"statuses/update response: %@", inResponseOrNil);
		
		if (inSuccessCallback)
		inSuccessCallback(inEngine, inResponseOrNil, inNotifyDelegate, inShouldRetry);

	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSLog(@"Failed. %@");
		
		if (inFailureCallback)
		inFailureCallback(inEngine, inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}





@end
