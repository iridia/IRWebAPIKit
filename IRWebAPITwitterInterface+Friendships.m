//
//  IRWebAPITwitterInterface+Friendships.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 4/3/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Friendships.h"


@implementation IRWebAPITwitterInterface (Friendships)

- (void) retrieveFriendIDsWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSMutableArray *returnedStatus = [NSMutableArray array]; // in the future, maybe mapped, sequential and mutable NSData object?
	
	

}

- (void) retrieveFriendIDsWithCursor:(unsigned long long)cursorID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);
		
	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/friends/ids.json"] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:cursorID]), @"cursor",
	
	nil] options:nil validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];	

}

@end
