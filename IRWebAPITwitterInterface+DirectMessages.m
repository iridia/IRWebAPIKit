//
//  IRWebAPITwitterInterface+DirectMessages.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/18/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+DirectMessages.h"


@implementation IRWebAPITwitterInterface (DirectMessages)

- (void) retrieveIncomingDirectMessagesWithRange:(IRWebAPITwitterDirectMessageIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/direct_messages.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:inRange.since]), @"since_id",
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:inRange.before]), @"max_id",
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_entities",

	nil] options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);

	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];	

}





- (void) retrieveOutgoingDirectMessagesWithRange:(IRWebAPITwitterDirectMessageIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/direct_messages/sent.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:inRange.since]), @"since_id",
		IRWebAPIKitNumberOrNull([NSNumber numberWithUnsignedLongLong:inRange.before]), @"max_id",
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_entities",

	nil] options:nil validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);

	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) sendDirectMessageToUser:(IRWebAPITwitterUserID)inUserID withContents:(NSString *)inContents successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/direct_messages/new.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		[NSNumber numberWithUnsignedLongLong:inUserID], @"user_id",
		inContents, @"text",
		[NSNumber numberWithBool:YES], @"include_entities",

	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);

	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) deleteDirectMessageWithID:(IRWebAPITwitterDirectMessageID)inMessageID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/direct_messages/destroy/%llu.json", inMessageID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSNumber numberWithUnsignedLongLong:inMessageID], @"id",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}

@end
