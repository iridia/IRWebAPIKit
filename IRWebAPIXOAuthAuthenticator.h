//
//  IRWebAPIXOAuthAuthenticator.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

//  OAUTH ON DESKTOP / MOBILE APPS IS A JOKE.
//  THERE IS NO OAUTH AUTHENTICATOR PROVIDED.

@class IRWebAPIAuthenticator;
@interface IRWebAPIXOAuthAuthenticator : IRWebAPIAuthenticator {

	NSString *realm;
	NSString *consumerKey;
	NSString *consumerSecret;
	
	NSURL *xAuthAccessTokenBaseURL;
	NSURL *authorizeURL;

}

@end
