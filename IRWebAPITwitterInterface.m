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

	IRWebAPIContext *twitterContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com"]] autorelease];

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

@end
