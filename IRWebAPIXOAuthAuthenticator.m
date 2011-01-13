//
//  IRWebAPIXOAuthAuthenticator.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"
#import "IRWebAPIXOAuthAuthenticator.h"


@interface IRWebAPIXOAuthAuthenticator ()

@property (nonatomic, retain, readwrite) IRWebAPICredentials *currentCredentials;

@end


@implementation IRWebAPIXOAuthAuthenticator

@synthesize consumerKey, consumerSecret, retrievedToken, retrievedTokenSecret;

- (id) initWithEngine:(IRWebAPIEngine *)inEngine {

	self = [super initWithEngine:inEngine]; if (!self) return nil;
	
	consumerKey = nil;
	consumerSecret = nil;
	retrievedToken = nil;
	retrievedTokenSecret = nil;
	
	xAuthAccessTokenBaseURL = nil;
	authorizeURL = nil;
	
	return self;

}

- (void) dealloc {

	self.consumerKey = nil;
	self.consumerSecret = nil;
	self.retrievedToken = nil;
	self.retrievedTokenSecret = nil;
	
	[super dealloc];

}

- (void) createTransformerBlocks {

	self.globalRequestPostTransformerBlock = ^ (NSDictionary *inOriginalContext) {
	
		IRWebAPIKitLog(@"Authenticator post transformer block invoked with context %@", inOriginalContext);
	
		NSMutableDictionary *mutatedContext = [inOriginalContext mutableCopy];
	
		BOOL (^isRequestAuthenticated)(void) = ^ {
			
			return (BOOL)(!!(self.retrievedTokenSecret));
		
		};
		
		BOOL (^isPOST)(void) = ^ {
		
			return [@"POST" isEqual:[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPMethod]];
		
		};
		
		BOOL removesQueryParameters = NO;
	
		if (isRequestAuthenticated() && isPOST()) {
		
			IRWebAPIKitLog(@"Request is invoked after authentication, and is a POST request.  Reforming.");
		
		//	If the user is previously authenticated, and this is a POST request, remove query parameters because IRWebAPIKit assumes that all “arguments” are query parameters.
		
		//	This is an ugly hack.  We should assume that all parameters are equal, then assign them as POST or Query parameters separately
		//	Or, there will be an even better way to do so
		
			NSString *POSTBody;
			NSMutableArray *POSTBodyElements = [NSMutableArray array];
			
			NSMutableDictionary *queryParams = [mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];

			for (id key in queryParams)
			[POSTBodyElements addObject:[NSString stringWithFormat:@"%@=%@", key, IRWebAPIKitRFC3986EncodedStringMake([queryParams objectForKey:key])]];
						
			POSTBody = [POSTBodyElements componentsJoinedByString:@"&"];
			IRWebAPIKitLog(@"POST body elements %@, body string %@", POSTBodyElements, POSTBody);
			
			[mutatedContext setObject:[POSTBody dataUsingEncoding:NSUTF8StringEncoding] forKey:kIRWebAPIEngineRequestHTTPBody];
			
			removesQueryParameters = YES;			

			[[mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields] setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
			
			IRWebAPIKitLog(@"Mutated context is %@", mutatedContext);
		
		}
		
		NSMutableDictionary *signatureStringParameters = [[[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPQueryParameters] mutableCopy] autorelease];
								
		NSMutableDictionary *oAuthParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			self.consumerKey, @"oauth_consumer_key",
			IRWebAPIKitNonce(), @"oauth_nonce",
			IRWebAPIKitTimestamp(), @"oauth_timestamp",
			@"HMAC-SHA1", @"oauth_signature_method",
			@"1.0", @"oauth_version",
		
		nil];

		if (self.retrievedToken)
		[oAuthParameters setObject:self.retrievedToken forKey:@"oauth_token"];
		
		for (id key in oAuthParameters)
		[signatureStringParameters setObject:[oAuthParameters objectForKey:key] forKey:key];

		NSString *baseSignatureString = IRWebAPIKitOAuthSignatureBaseStringMake(

			[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPMethod],
			[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPBaseURL],
			signatureStringParameters
			
		);
		
		[oAuthParameters setObject:IRWebAPIKitHMACSHA1(self.consumerSecret, self.retrievedTokenSecret, baseSignatureString) forKey:@"oauth_signature"];
		
		NSMutableArray *oAuthHeaderContents = [NSMutableArray array];
		
		for (id key in oAuthParameters) {
		
			[oAuthHeaderContents addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, IRWebAPIKitRFC3986EncodedStringMake([oAuthParameters objectForKey:key])]];
		
		}
		
		[(NSMutableDictionary *)[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPHeaderFields] setObject:[NSString stringWithFormat:@"OAuth %@", [oAuthHeaderContents componentsJoinedByString:@", "]] forKey:@"Authorization"];
		
		IRWebAPIKitLog(@"Returned mutated context is %@", mutatedContext);
		
		if (removesQueryParameters)
		[mutatedContext setObject:[NSMutableArray array] forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			
		return [mutatedContext autorelease];
	
	};

}

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine {

	[self disassociateEngine];

	self.engine = inEngine;
//	Clear stuff?
	
	[super associateWithEngine:inEngine];

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	[self.engine fireAPIRequestNamed:@"oauth/access_token" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		inCredentials.identifier, @"x_auth_username",
		inCredentials.qualifier, @"x_auth_password",
		@"client_auth", @"x_auth_mode",

	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIResponseQueryResponseParserMake(), kIRWebAPIEngineParser,
		@"POST", kIRWebAPIEngineRequestHTTPMethod,
			
	nil] validator: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
		if (!inResponseOrNil) return NO;
	
		NSLog(@"Validating response %@", inResponseOrNil);
	
		for (id key in [NSArray arrayWithObjects:@"oauth_token", @"oauth_token_secret", nil])
		if (!IRWebAPIKitValidResponse([inResponseOrNil objectForKey:key]))
		return NO;
		
		return YES;
	
	} successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		self.retrievedToken = [inResponseOrNil valueForKey:@"oauth_token"];
		self.retrievedTokenSecret = [inResponseOrNil valueForKey:@"oauth_token_secret"];

		self.currentCredentials = inCredentials;
		self.currentCredentials.authenticated = YES;

		[self.currentCredentials.userInfo setObject:self.retrievedToken forKey:@"oauth_token"];
		[self.currentCredentials.userInfo setObject:self.retrievedTokenSecret forKey:@"oauth_token_secret"];

		if (successHandler)
		successHandler(self, YES, inShouldRetry);
		
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSLog(@"XOAuth AUTH FAIL %@", inResponseOrNil);
	
		if (failureHandler)
		failureHandler(self, NO, inShouldRetry);
	
	}];

}

@end
