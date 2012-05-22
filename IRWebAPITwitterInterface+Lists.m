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

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);
		
	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists%@.json", self.authenticator.currentCredentials.identifier, ((^{
	
		switch (inListType) {
			case IRWebAPITwitterListsMadeByUser: return @"";
			case IRWebAPITwitterListsIncludingUser: return @"/memberships";
			case IRWebAPITwitterListsSubscribedByUser: return @"/subscriptions";
		}
		
	})())] withArguments:nil options:nil validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) retrieveStatusesFromList:(IRWebAPITwitterListID)inListID withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);
		
	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/%llu/statuses.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:inRange.since]), @"since_id",
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:inRange.before]), @"max_id",
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];	

}





- (void) createListWithName:(NSString *)inName description:(NSString *)inDescription becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/.json", self.authenticator.currentCredentials.identifier] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		inName, @"name",
		(inListBecomesPrivate ? @"private" : @"public"), @"mode",
		inDescription, @"description",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];	

}





- (void) updateList:(IRWebAPITwitterListID)inListID withName:(NSString *)inName description:(NSString *)inDescription becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/%llu.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		inName, @"name",
		(inListBecomesPrivate ? @"private" : @"public"), @"mode",
		inDescription, @"description",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) deleteList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/lists/%llu.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		@"DELETE", @"_method",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) retrieveMembersOfList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/%llu/members.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSString stringWithFormat:@"%llu", inListID], @"id",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) removeMember:(IRWebAPITwitterUserID)inUserID fromList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/%llu/members.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		@"DELETE", @"_method",
		[NSString stringWithFormat:@"%llu", inUserID], @"id",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) addMember:(IRWebAPITwitterUserID)inUserID toList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/%@/%llu/members.json", self.authenticator.currentCredentials.identifier, inListID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSString stringWithFormat:@"%llu", inUserID], @"id",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}

@end