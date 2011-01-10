//
//  IRWebAPITwitterInterface+Timeline.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/17/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Timeline.h"


@implementation IRWebAPITwitterInterface (Timeline)

- (void) retrieveStatusesFromTimeline:(IRWebAPITwitterTimelineType)inTimelineType withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSString * (^methodNameForType) (IRWebAPITwitterTimelineType) = ^ NSString * (IRWebAPITwitterTimelineType inType) {
	
		if (inType == IRWebAPITwitterTimelineHome)
		return @"statuses/home_timeline.json";
		
		return @"statuses/user_timeline.json";
	
	}; 
	
	[self.engine fireAPIRequestNamed:methodNameForType(inTimelineType) withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull(inRange.since), @"since_id",
		IRWebAPIKitNumberOrNull(inRange.before), @"max_id",
		[NSNumber numberWithInt:10], @"count",
	
	nil] options:nil validator: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
	//	We might need something that is more concise here?
	
		id response = [inResponseOrNil valueForKeyPath:@"response"];
	
		if ([response isEqual:[NSNull null]])
		return NO;
	
		if (![response isKindOfClass:[NSArray class]])
		return NO;
		
		if ([[[(NSArray *)response objectAtIndex:0] valueForKeyPath:@"text"] isEqual:[NSNull null]])
		return NO;
		
		return YES;
	
	} successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}





- (void) retrieveMentionsWithRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"statuses/mentions.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull(inRange.since), @"since_id",
		IRWebAPIKitNumberOrNull(inRange.before), @"max_id",
		[NSNumber numberWithInt:200], @"count",
		[NSNumber numberWithBool:YES], @"include_rts",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:nil successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
	
		NSLog(@"retrieveMentionsSince.  Retrieved response %@", inResponseOrNil);
		
		if (inSuccessCallback)
		inSuccessCallback([inResponseOrNil valueForKeyPath:@"response"], inNotifyDelegate, inShouldRetry);
	 
	} failureHandler:nil];

}

@end
