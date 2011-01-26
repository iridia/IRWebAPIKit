//
//  IRWebAPITwitterInterface.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

#ifndef __IRWebAPITwitterInterface__
#define __IRWebAPITwitterInterface__


typedef uint64_t IRWebAPITwitterStatusID;
#define IRWebAPITwitterStatusIdentifierNotApplicable 0

typedef struct IRWebAPITwitterStatusIDRange {
	
	IRWebAPITwitterStatusID since;
	IRWebAPITwitterStatusID before;
	
} IRWebAPITwitterStatusIDRange;

#define IRWebAPITwitterStatusIDRangeNull ((IRWebAPITwitterStatusIDRange){0, 0})


static inline IRWebAPITwitterStatusIDRange IRWebAPITwitterStatusIDRangeMake (IRWebAPITwitterStatusID begin, IRWebAPITwitterStatusID end) {
	
	IRWebAPITwitterStatusIDRange returnedRange;

	returnedRange.since = begin;
	returnedRange.before = end;
	
	return returnedRange;
	
}

typedef uint64_t IRWebAPITwitterUserID;
typedef uint64_t IRWebAPITwitterListID;
typedef uint64_t IRWebAPITwitterDirectMessageID;

typedef IRWebAPITwitterStatusIDRange IRWebAPITwitterDirectMessageIDRange;

static inline IRWebAPITwitterDirectMessageIDRange IRWebAPITwitterDirectMessageIDRangeMake (IRWebAPITwitterDirectMessageID begin, IRWebAPITwitterDirectMessageID end) {

	IRWebAPITwitterDirectMessageIDRange returnedRange;

	returnedRange.since = begin;
	returnedRange.before = end;
	
	return returnedRange;
	
}

#endif





@interface IRWebAPITwitterInterface : IRWebAPIInterface <IRWebAPIInterfaceAuthenticating, IRWebAPIInterfaceXOAuthAuthenticating>

@property (nonatomic, readwrite, assign) NSUInteger defaultBatchSize;

- (void) updateStatusForCurrentUserWithContents:(NSString *)inContents userInfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) lookupCurrentUserWithSuccessHandler:(IRWebAPIInterfaceCallback)inSuccessHandler failureHandler:(IRWebAPIInterfaceCallback)inFailureHandler;

@end





#import "IRWebAPITwitterInterface+Validators.h"

#import "IRWebAPITwitterInterface+Timeline.h"
#import "IRWebAPITwitterInterface+Geo.h"
#import "IRWebAPITwitterInterface+Lists.h"
#import "IRWebAPITwitterInterface+DirectMessages.h"




