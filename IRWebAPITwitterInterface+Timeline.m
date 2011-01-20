//
//  IRWebAPITwitterInterface+Timeline.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/17/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Timeline.h"
#import "IRWebAPITwitterInterface+Validators.h"

@implementation IRWebAPITwitterInterface (Timeline)

- (void) retrieveStatusesFromTimeline:(IRWebAPITwitterTimelineType)inTimelineType withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSString * (^methodNameForType) (IRWebAPITwitterTimelineType) = ^ NSString * (IRWebAPITwitterTimelineType inType) {
	
		if (inType == IRWebAPITwitterTimelineHome)
		return @"1/statuses/home_timeline.json";
		
		return @"1/statuses/user_timeline.json";
	
	}; 
	
	[self.engine fireAPIRequestNamed:methodNameForType(inTimelineType) withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull(inRange.since), @"since_id",
		IRWebAPIKitNumberOrNull(inRange.before), @"max_id",
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) retrieveMentionsWithRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/statuses/mentions.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		IRWebAPIKitNumberOrNull(inRange.since), @"since_id",
		IRWebAPIKitNumberOrNull(inRange.before), @"max_id",
		[NSNumber numberWithInt:self.defaultBatchSize], @"count",
		[NSNumber numberWithBool:YES], @"include_rts",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) retrieveRetweetsOfType:(IRWebAPITwitterRetweetType)inType withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSString *requestName = ((^{
	
		switch (inType) {
		
			case IRWebAPITwitterRetweetByUser: return @"1/statuses/retweeted_by_me.json";
			case IRWebAPITwitterRetweetByFollowers: return @"1/statuses/retweeted_to_me.json";
			case IRWebAPITwitterRetweetOfUser: return @"1/statuses/retweets_of_me.json";
			default: return nil;
		
		}
	
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
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];
	
}





- (void) retrieveFavoritesWithRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:@"1/favorites.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
	//	The range / count currently is not even supported as the API returns only the latest 20 tweets
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:nil validator:[self defaultTimelineValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





- (void) setStatus:(IRWebAPITwitterStatusID)inID asFavorited:(BOOL)inBecomesFavorited successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/favorites/%@/%llu.json", (inBecomesFavorited ? @"create" : @"destroy"), inID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSNumber numberWithUnsignedLongLong:inID], @"id",
		[NSNumber numberWithBool:YES], @"include_entities",
	
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





- (void) retweetStatus:(IRWebAPITwitterStatusID)inID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	[self.engine fireAPIRequestNamed:[NSString stringWithFormat:@"1/statuses/retweet/%llu.json", inID] withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSNumber numberWithUnsignedLongLong:inID], @"id",
		[NSNumber numberWithBool:YES], @"include_entities",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:

		@"POST", kIRWebAPIEngineRequestHTTPMethod,

	nil] validator:[self defaultSingleTweetValidator] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	 
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}





@end
