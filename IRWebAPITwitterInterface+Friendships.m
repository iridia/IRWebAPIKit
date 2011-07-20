//
//  IRWebAPITwitterInterface+Friendships.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 4/3/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Friendships.h"


@implementation IRWebAPITwitterInterface (Friendships)

+ (BOOL) repeatedlyCalledSuccessHandlerResponseExhausted:(NSDictionary *)response {

	if (!response || ![[response objectForKey:@"ids"] count])
	return YES;
	
	if ([[response objectForKey:@"next_cursor"] isEqual:[response objectForKey:@"previous_cursor"]])
	return YES;
	
	return NO;

}

- (void) retrieveFriendsOfUser:(IRWebAPITwitterUserID)userID withConcatenatedSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self retrieveFriendsOfUser:userID withCallbackStyle:IRWebAPIInterfaceCallbackStyleConcatenatedCallback successHandler:inSuccessCallback failureHandler:inFailureCallback];

}

- (void) retrieveFriendsOfUser:(IRWebAPITwitterUserID)userID withRepeatedlyCalledSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self retrieveFriendsOfUser:userID withCallbackStyle:IRWebAPIInterfaceCallbackStyleManyCallbacks successHandler:inSuccessCallback failureHandler:inFailureCallback];

}

- (void) retrieveFriendsOfUser:(IRWebAPITwitterUserID)userID withCallbackStyle:(IRWebAPIInterfaceCallbackStyle)style successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSMutableDictionary *actualResponseOrNil = [NSMutableDictionary dictionary]; //	Get everything

	void (^enqueueIdentifiersFromResponse)(NSDictionary *response) = ^ (NSDictionary *response) {
	
		NSMutableArray *actualIDs = [actualResponseOrNil objectForKey:@"ids"];
		
		if (![actualIDs isKindOfClass:[NSMutableArray class]]) {
		
			actualIDs = [[actualIDs mutableCopy] autorelease];
			[actualResponseOrNil setObject:actualIDs forKey:@"ids"];
		
		}
		
		[actualIDs addObjectsFromArray:[response objectForKey:@"ids"]];
	
	};
	
	BOOL (^responseExhausted)(NSDictionary *responseBody) = ^ (NSDictionary *responseBody) { return [[self class] repeatedlyCalledSuccessHandlerResponseExhausted:responseBody]; };
	
	__block void (^workingBlock)(unsigned long long queuedCursorID);
	
	workingBlock = ^ (unsigned long long queuedCursorID) {
	
		[self retrieveFriendsOfUser:userID withCursor:queuedCursorID successHandler: ^ (NSDictionary *inResponseOrNil, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
			switch (style) {
			
				case IRWebAPIInterfaceCallbackStyleConcatenatedCallback: {
			
					enqueueIdentifiersFromResponse(inResponseOrNil);
			
					if (responseExhausted(inResponseOrNil)) {
					
						if (inSuccessCallback)
						inSuccessCallback(actualResponseOrNil, outNotifyDelegate, outShouldRetry);
					
						return;
					
					}
						
					break;
				
				}
				
				case IRWebAPIInterfaceCallbackStyleManyCallbacks : {
				
					if (inSuccessCallback)
					inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
			
					if (responseExhausted(inResponseOrNil)) {

						return;
					
					}

					break;
				
				}
				
				default: {
				
					NSParameterAssert(NO);
				
				}
			
			}
					
			workingBlock([[inResponseOrNil objectForKey:@"next_cursor"] unsignedLongLongValue]);
		
		} failureHandler: ^ (NSDictionary *inResponseOrNil, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
			NSLog(@"FAIL %@", inResponseOrNil);
		
		}];
	
	};
	
	workingBlock(-1); // -1 starts pagination, and the cursor defaults to -1 per official docs

}

- (void) retrieveFriendsOfUser:(IRWebAPITwitterUserID)userID withCursor:(unsigned long long)cursorID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.authenticator.currentCredentials.identifier, @"Error: %s requires that the current credentials be present.", __PRETTY_FUNCTION__);
		
	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/friends/ids.json"] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:cursorID]), @"cursor",
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:userID]), @"user_id",
	
	nil] options:nil validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];	

}

@end
