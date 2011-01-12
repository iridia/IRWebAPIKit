//
//  IRWebAPITwitterInterface+Timeline.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/17/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Timeline.h"


@interface IRWebAPITwitterInterface (TimelinePrivate)

- (IRWebAPIResposeValidator) defaultTimelineValidator;

@end

@implementation IRWebAPITwitterInterface (TimelinePrivate)

- (IRWebAPIResposeValidator) defaultTimelineValidator {

	return [[(^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
	//	We might need something that is more concise here?
	
		id response = [inResponseOrNil valueForKeyPath:@"response"];
	
		if ([response isEqual:[NSNull null]])
		return NO;
	
		if (![response isKindOfClass:[NSArray class]])
		return NO;
		
		if ([[[(NSArray *)response objectAtIndex:0] valueForKeyPath:@"text"] isEqual:[NSNull null]])
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

@end





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
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
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
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_rts",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}





- (void) retrieveRetweetsOfType:(IRWebAPITwitterRetweetType)inType withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSString *requestName = ((^{
	
		switch (inType) {
		
			case IRWebAPITwitterRetweetByUser: return @"statuses/retweeted_by_me.json";
			case IRWebAPITwitterRetweetByFollowers: return @"statuses/retweeted_to_me.json";
			case IRWebAPITwitterRetweetOfUser: return @"statuses/retweets_of_me.json";
		
		}
		
		return nil;
	
	})());
	
	if (!requestName) {
	
		NSLog(@"Error: %s failed because of an unknown IRWebAPITwitterRetweetType.", (char *)_cmd);
	
	}

	[self.engine fireAPIRequestNamed:requestName withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull(inRange.since), @"since_id",
		IRWebAPIKitNumberOrNull(inRange.before), @"max_id",
		[NSNumber numberWithInt:MIN(100, self.defaultBatchSize)], @"count",
		[NSNumber numberWithBool:YES], @"include_rts",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];
	
}

@end
