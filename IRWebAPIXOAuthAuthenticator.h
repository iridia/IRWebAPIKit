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

	NSString *consumerKey;
	NSString *consumerSecret;

	NSString *retrievedToken;
	NSString *retrievedTokenSecret;
	
	NSURL *xAuthAccessTokenBaseURL;
	NSURL *authorizeURL;

}

@property (nonatomic, readwrite, retain) NSString *consumerKey;
@property (nonatomic, readwrite, retain) NSString *consumerSecret;

@property (nonatomic, readwrite, retain) NSString *retrievedToken;
@property (nonatomic, readwrite, retain) NSString *retrievedTokenSecret;
	
@end
