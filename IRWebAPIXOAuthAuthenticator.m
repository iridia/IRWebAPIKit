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
@synthesize currentCredentials;

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
		
		NSMutableDictionary *mutatedContext = [inOriginalContext mutableCopy];
		NSMutableDictionary *mutatedContextHeaderFields = (NSMutableDictionary *)[mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields];
	
		BOOL	isRequestAuthenticated = (BOOL)(!!(self.retrievedTokenSecret)),
			isPOST = [@"POST" isEqual:[mutatedContext valueForKey:kIRWebAPIEngineRequestHTTPMethod]],
			removesQueryParameters = NO;
					
		if (isRequestAuthenticated && isPOST) {
		
			[mutatedContext setObject:((^ {

				NSMutableArray *POSTBodyElements = [NSMutableArray array];
				
				[[mutatedContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
					
					[POSTBodyElements addObject:[NSString stringWithFormat:@"%@=%@", key, IRWebAPIKitRFC3986EncodedStringMake(obj)]];
					
				}];
			
				return [[POSTBodyElements componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
			
			})()) forKey:kIRWebAPIEngineRequestHTTPBody];
			
			[mutatedContextHeaderFields setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
			
			removesQueryParameters = YES;
		
		}
		
		[mutatedContextHeaderFields setObject:[self oAuthHeaderValueForRequestContext:mutatedContext] forKey:@"Authorization"];
		
		if (removesQueryParameters)
		[mutatedContext setObject:[NSMutableArray array] forKey:kIRWebAPIEngineRequestHTTPQueryParameters];
		
		IRWebAPIKitLog(@"mutatedContext %@", mutatedContext);
			
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
			
	nil] validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inRequestContext) {
	
		if (!([IRWebAPIInterface defaultNoErrorValidator])(inResponseOrNil, inRequestContext))
		return NO;
	
		for (id key in [NSArray arrayWithObjects:@"oauth_token", @"oauth_token_secret", nil])
		if (!IRWebAPIKitValidResponse([inResponseOrNil objectForKey:key]))
		return NO;
		
		return YES;
	
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		self.retrievedToken = [inResponseOrNil valueForKey:@"oauth_token"];
		self.retrievedTokenSecret = [inResponseOrNil valueForKey:@"oauth_token_secret"];

		self.currentCredentials = inCredentials;
		self.currentCredentials.authenticated = YES;

		[self.currentCredentials.userInfo setObject:self.retrievedToken forKey:@"oauth_token"];
		[self.currentCredentials.userInfo setObject:self.retrievedTokenSecret forKey:@"oauth_token_secret"];
		
		NSParameterAssert(self.currentCredentials && self.currentCredentials.authenticated);

		if (successHandler)
		successHandler(self, YES, outShouldRetry);
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		self.currentCredentials.authenticated = NO;
		self.retrievedToken = nil;
		self.retrievedTokenSecret = nil;
	
		NSLog(@"XOAuth FAIL %@, %@", inResponseOrNil, inResponseContext);
	
		if (failureHandler)
		failureHandler(self, NO, outShouldRetry);
	
	}];

}





- (NSDictionary *) oAuthHeaderValuesForHTTPMethod:(NSString *)inHTTPMethod baseURL:(NSURL *)inBaseURL arguments:(NSDictionary *)inMethodArguments {

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSMutableDictionary *signatureStringParameters = [NSMutableDictionary dictionary];
	
	NSMutableDictionary *oAuthParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:

		self.consumerKey, @"oauth_consumer_key",
		IRWebAPIKitNonce(), @"oauth_nonce",
		IRWebAPIKitTimestamp(), @"oauth_timestamp",
		@"HMAC-SHA1", @"oauth_signature_method",
		@"1.0", @"oauth_version",

	nil];
	
	if (self.retrievedToken)
	[oAuthParameters setObject:self.retrievedToken forKey:@"oauth_token"];
	
	
	[signatureStringParameters addEntriesFromDictionary:oAuthParameters];
	
	[inMethodArguments enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
	
		[signatureStringParameters setObject:IRWebAPIKitRFC3986EncodedStringMake(obj) forKey:key];
	
	}];
	
	NSString *signatureBaseString = IRWebAPIKitOAuthSignatureBaseStringMake(
		
		inHTTPMethod, inBaseURL, signatureStringParameters
			
	);
	
	[oAuthParameters setObject:IRWebAPIKitHMACSHA1(
	
		self.consumerSecret, 
		self.retrievedTokenSecret, 
		signatureBaseString
	
	) forKey:@"oauth_signature"];	
	
	[oAuthParameters retain];
	[pool drain];
	
	IRWebAPIKitLog(@"oAuthHeaderValuesForHTTPMethod -> %@", oAuthParameters);
	
	return [oAuthParameters autorelease];
	
}





- (NSString *) oAuthHeaderValueForHTTPMethod:(NSString *)inHTTPMethod baseURL:(NSURL *)inBaseURL arguments:(NSDictionary *)inMethodArguments {
	
	NSDictionary *headerValues = [self oAuthHeaderValuesForHTTPMethod:inHTTPMethod baseURL:inBaseURL arguments:inMethodArguments];
	
	NSMutableArray *contents = [NSMutableArray array];
	
	for (id aKey in headerValues)
	[contents addObject:[NSString stringWithFormat:
	
		@"%@=\"%@\"", 
		aKey, IRWebAPIKitRFC3986EncodedStringMake([headerValues objectForKey:aKey])
	
	]];
	
	return [NSString stringWithFormat:@"OAuth %@", [contents componentsJoinedByString:@", "]];
	
}

- (NSString *) oAuthHeaderValueForRequestContext:(NSDictionary *)inRequestContext {

	return 	[self oAuthHeaderValueForHTTPMethod:[inRequestContext valueForKey:kIRWebAPIEngineRequestHTTPMethod] baseURL:[inRequestContext valueForKey:kIRWebAPIEngineRequestHTTPBaseURL] arguments:[inRequestContext valueForKey:kIRWebAPIEngineRequestHTTPQueryParameters]];

}

@end
