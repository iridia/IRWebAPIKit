//
//  IRWebAPITwitterInterface+Timeline.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/17/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Timeline.h"


@implementation IRWebAPITwitterInterface (Timeline)

- (void) retrieveTimeline:(IRWebAPITwitterTimelineType)inTimelineType since:(IRWebAPITwitterStatusIdentifier)inSinceIdentifierOrNil before:(IRWebAPITwitterStatusIdentifier)inBeforeIdentifierOrNil onSuccess:(IRWebAPICallback)inSuccessCallback onFailure:(IRWebAPICallback)inFailureCallback {

	NSString * (^methodNameForType) (IRWebAPITwitterTimelineType) = ^ NSString * (IRWebAPITwitterTimelineType inType) {
	
		if (inType == IRWebAPITwitterTimelineHome)
		return @"statuses/home_timeline";
		
		return @"statuses/user_timeline";
	
	}; 
	
	[self.engine fireAPIRequestNamed:methodNameForType(inTimelineType) withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		(inSinceIdentifierOrNil == 0) ? (id)[NSNull null] : (id)[NSNumber numberWithInt:inSinceIdentifierOrNil], @"since_id",
		(inBeforeIdentifierOrNil == 0) ? (id)[NSNull null] : (id)[NSNumber numberWithInt:inBeforeIdentifierOrNil], @"max_id",
	
	nil] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSLog(@"timeline success with response %@");
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSLog(@"timeline failure with response %@");
	
	}];

}

@end
