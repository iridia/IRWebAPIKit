//
//  IRWebAPITwitterInterface+Timeline.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/17/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Timeline.h"


@implementation IRWebAPITwitterInterface (Timeline)

- (void) retrieveTimeline:(IRWebAPITwitterTimelineType)inTimelineType since:(IRWebAPITwitterStatusIdentifier)inSinceIdentifier before:(IRWebAPITwitterStatusIdentifier)inBeforeIdentifier successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSString * (^methodNameForType) (IRWebAPITwitterTimelineType) = ^ NSString * (IRWebAPITwitterTimelineType inType) {
	
		if (inType == IRWebAPITwitterTimelineHome)
		return @"statuses/home_timeline.json";
		
		return @"statuses/user_timeline.json";
	
	}; 
	
	[self.engine fireAPIRequestNamed:methodNameForType(inTimelineType) withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		(inSinceIdentifier == 0) ? (id)[NSNull null] : (id)[NSNumber numberWithInt:inSinceIdentifier], @"since_id",
		(inBeforeIdentifier == 0) ? (id)[NSNull null] : (id)[NSNumber numberWithInt:inBeforeIdentifier], @"max_id",
	//	[NSNumber numberWithBool:YES], @"trim_user",
	
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
		inSuccessCallback([inResponseOrNil valueForKeyPath:@"response"], inNotifyDelegate, inShouldRetry);
	 
	} failureHandler: ^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry) {
		
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, inNotifyDelegate, inShouldRetry);
	
	}];

}

@end
