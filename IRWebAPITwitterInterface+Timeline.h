//
//  IRWebAPITwitterInterface+Timeline.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/17/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"





#ifndef __IRWebAPIInterface__Timeline__
#define __IRWebAPIInterface__Timeline__

typedef enum {

//	IRWebAPITwitterTimelinePublic,
	IRWebAPITwitterTimelineHome,
	IRWebAPITwitterTimelineUser

} IRWebAPITwitterTimelineType;

#endif





@interface IRWebAPITwitterInterface (Timeline)

- (void) retrieveStatusesFromTimeline:(IRWebAPITwitterTimelineType)inTimelineType withRange:(IRWebAPITwitterStatusIDRange)range successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) retrieveMentionsWithRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

@end
