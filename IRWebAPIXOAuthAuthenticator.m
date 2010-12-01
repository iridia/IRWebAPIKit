//
//  IRWebAPIXOAuthAuthenticator.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"
#import "IRWebAPIXOAuthAuthenticator.h"


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

- (void) createTransformerBlocks {

	self.globalRequestPostTransformerBlock = [[^ (NSDictionary *inOriginalContext) {

		NSMutableDictionary *mutatedContext = [inOriginalContext mutableCopy];
	
		BOOL (^isRequestAuthenticated)(void) = ^ {
			
			return (BOOL)(!!(self.retrievedTokenSecret));
		
		};
		
		BOOL (^isPOST)(void) = ^ {
		
			return [@"POST" isEqual:[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPMethod]];
		
		};
	
		if (isRequestAuthenticated() && isPOST()) {
		
		//	If the user is previously authenticated, and this is a POST request, remove query parameters because IRWebAPIKit assumes that all “arguments” are query parameters.
		
			NSString *POSTBody;
			NSMutableArray *POSTBodyElements = [NSMutableArray array];
			
			NSMutableDictionary *queryParams = [mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];

			for (id key in queryParams)
			[POSTBodyElements addObject:[NSString stringWithFormat:@"%@=%@", key, IRWebAPIKitOAuthParameterStringMake([queryParams objectForKey:key])]];
			
			POSTBody = [POSTBodyElements componentsJoinedByString:@"&"];
			
			[mutatedContext setObject:[POSTBody dataUsingEncoding:NSUTF8StringEncoding] forKey:kIRWebAPIEngineRequestHTTPBody];
			
			[mutatedContext setObject:[NSMutableArray array] forKey:kIRWebAPIEngineRequestHTTPQueryParameters];

			[[mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields] setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
		
		}
		
		NSMutableDictionary *signatureStringParameters = (isRequestAuthenticated() && isPOST()) ? [NSMutableDictionary dictionary] : [[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPQueryParameters] mutableCopy];
						
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
		
		if (isRequestAuthenticated() && isPOST())
		baseSignatureString = [baseSignatureString stringByAppendingFormat:@"%@%@",
		
			@"%26",
		
			IRWebAPIKitOAuthParameterStringMake([[NSString alloc] initWithData:[mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPBody] encoding:NSUTF8StringEncoding])
			
		];
		
		[oAuthParameters setObject:IRWebAPIKitHMACSHA1(self.consumerSecret, self.retrievedTokenSecret, baseSignatureString) forKey:@"oauth_signature"];
		
		NSMutableArray *oAuthHeaderContents = [NSMutableArray array];
		
		for (id key in oAuthParameters)
		[oAuthHeaderContents addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, IRWebAPIKitOAuthParameterStringMake([oAuthParameters objectForKey:key])]];
		
		[(NSMutableDictionary *)[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPHeaderFields] setObject:[NSString stringWithFormat:@"OAuth %@", [oAuthHeaderContents componentsJoinedByString:@", "]] forKey:@"Authorization"];
			
		return mutatedContext;
	
	} copy] retain];

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
			
	nil] onSuccess: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {

		if (![[inResponseOrNil valueForKey:@"oauth_token"] isEqual:[NSNull null]])
		self.retrievedToken = [inResponseOrNil valueForKey:@"oauth_token"];
		
		if (![[inResponseOrNil valueForKey:@"oauth_token_secret"] isEqual:[NSNull null]])
		self.retrievedTokenSecret = [inResponseOrNil valueForKey:@"oauth_token_secret"];
		
		if (!!self.retrievedToken && !!self.retrievedTokenSecret) {
		
			self.currentCredentials = inCredentials;
			
			[self.currentCredentials.userInfo setObject:self.retrievedToken forKey:@"oauth_token"];
			[self.currentCredentials.userInfo setObject:self.retrievedTokenSecret forKey:@"oauth_token_secret"];
		
			if (successHandler)
			successHandler(self, YES, inShouldRetry);
		
		} else {
		
			if (failureHandler)
			failureHandler(self, NO, inShouldRetry);
		
		}
	
	} onFailure: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		if (failureHandler)
		failureHandler(self, NO, inShouldRetry);
	
	}];

}

@end