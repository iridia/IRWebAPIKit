//
//  IRWebAPITwitterInterface+Lists.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Lists.h"


@implementation IRWebAPITwitterInterface (Lists)

- (void) retrieveListsOfType:(IRWebAPITwitterListsType)inListType successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.  Calling failure handler.", __PRETTY_FUNCTION__);
		
	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists%@.json", self.authenticator.currentCredentials.identifier, ((^{
	
		switch (inListType) {
		
			case IRWebAPITwitterListsMadeByUser: return @"";
			case IRWebAPITwitterListsIncludingUser: return @"/memberships";
			case IRWebAPITwitterListsSubscribedByUser: return @"/subscriptions";
		
		}
		
		NSAssert(NO, @"Serious breach of contract: unrecognized IRWebAPITwitterListsType.");
		
		return IRWebAPITwitterListsMadeByUser;
		
	})())] withArguments:nil options:nil validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}





- (void) retrieveStatusesFromList:(IRWebAPITwitterListID)inListID withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.  Calling failure handler.", __PRETTY_FUNCTION__);
		
	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/%llu/statuses.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull(inRange.since), @"since_id",
		IRWebAPIKitNumberOrNull(inRange.before), @"max_id",
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];	

}





- (void) createListWithName:(NSString *)inName description:(NSString *)inDescription becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.  Calling failure handler.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/.json", self.authenticator.currentCredentials.identifier] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		inName, @"name",
		(inListBecomesPrivate ? @"private" : @"public"), @"mode",
		inDescription, @"description",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];	

}





- (void) updateList:(IRWebAPITwitterListID)inListID withName:(NSString *)inName description:(NSString *)inDescription becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.  Calling failure handler.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/%llu.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		inName, @"name",
		(inListBecomesPrivate ? @"private" : @"public"), @"mode",
		inDescription, @"description",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}





- (void) deleteList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.  Calling failure handler.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/%llu.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		@"DELETE", @"_method",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}

@end