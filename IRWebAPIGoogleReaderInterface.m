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
	IRWebAPIAuthenticator *googleReaderAuthenticator = [[IRWebAPIGoogleReaderAuthenticator alloc] initWithEngine:googleReaderEngine];
	
	googleReaderEngine.parser = IRWebAPIResponseDefaultJSONParserMake();
	
	self = [self initWithEngine:googleReaderEngine authenticator:googleReaderAuthenticator];
	if (!self) return nil;
	
	
	[self.engine.globalRequestPreTransformers addObject:[[ ^ (NSDictionary *inOriginalContext) {
		
		NSMutableDictionary *transformedContext = [[inOriginalContext mutableCopy] autorelease];
		NSMutableDictionary *queryParameters = [transformedContext valueForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
		
		[queryParameters setObject:@"IRWebAPIKit" forKey:@"client"];
		[queryParameters setObject:[NSNumber numberWithFloat:[[NSDate date] timeIntervalSince1970]] forKey:@"ck"];
		[queryParameters setObject:@"json" forKey:@"output"];
		
		return (NSDictionary *)transformedContext;
	
	} copy] autorelease]];
	
	
	return self;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	[self.authenticator authenticateCredentials:inCredentials onSuccess: ^ (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry) {
	
		if (!isAuthenticated) {
		
			*inShouldRetry = YES;
			return;
		
		}

		if (successHandler)
		successHandler(inAuthenticator, isAuthenticated, inShouldRetry);
	
	} onFailure:failureHandler];

}

- (void) retrieveCurrentUserInfoWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"reader/api/0/user-info" withArguments:nil options:nil validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		for (id aKey in [NSArray arrayWithObjects:@"userEmail", @"userId", @"userName", nil])
		if ([inResponseOrNil objectForKey:aKey] == nil)
		return NO;
		
		return YES;
	
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}

- (void) retrieveFeedsWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"reader/api/0/unread-count" withArguments:nil options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}

- (void) retrieveItemsOfFeed:(NSURL *)feedURL crawledAfterDate:(NSDate *)crawledDate excluding:(NSArray *)itemsOrStates successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(NO, @"Implement %s", __PRETTY_FUNCTION__);

}

- (void) retrieveItemsWithLabel:(NSString *)aLabelName crawledAfterDate:(NSDate *)crawledDate excluding:(NSArray *)itemsOrStates successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(NO, @"Implement %s", __PRETTY_FUNCTION__);

}

- (void) retrieveReadingListItemsCrawledAfterDate:(NSDate *)crawledDate excluding:(NSArray *)itemsOrStates successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(NO, @"Implement %s", __PRETTY_FUNCTION__);

}

- (void) retrieveStarredItemsWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(NO, @"Implement %s", __PRETTY_FUNCTION__);

}

- (void) retrieveSharedItemsWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(NO, @"Implement %s", __PRETTY_FUNCTION__);

}

- (void) retrieveNotesWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(NO, @"Implement %s", __PRETTY_FUNCTION__);

}

@end
