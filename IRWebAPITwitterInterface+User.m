//
//  IRWebAPITwitterInterface+User.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 4/5/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+User.h"


@implementation IRWebAPITwitterInterface (User)

- (void) retrieveMetadataForUserWithIdentifiers:(NSArray *)identifiers withSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/users/lookup.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[identifiers componentsJoinedByString:@","], @"user_id",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultNoErrorValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}

- (void) retrieveMetadataForUser:(IRWebAPITwitterUserID)anUserID withSuccessHandler:(IRWebAPIInterfaceCallback)successBlock failureHandler:(IRWebAPIInterfaceCallback)failureBlock {

	//	Just a convenience!

	return [self retrieveMetadataForUserWithIdentifiers:[NSArray arrayWithObject:[NSNumber numberWithUnsignedLongLong:anUserID]] withSuccessHandler:successBlock failureHandler:failureBlock];

}

@end
