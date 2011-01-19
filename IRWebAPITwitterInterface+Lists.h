//
//  IRWebAPITwitterInterface+Lists.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"





#ifndef __IRWebAPIInterface__Lists__
#define __IRWebAPIInterface__Lists__

typedef enum {

	IRWebAPITwitterListsMadeByUser,
	IRWebAPITwitterListsIncludingUser,
	IRWebAPITwitterListsSubscribedByUser

} IRWebAPITwitterListsType;

#endif





@interface IRWebAPITwitterInterface (Lists)

- (void) retrieveListsOfType:(IRWebAPITwitterListsType)inListType successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) retrieveStatusesFromList:(IRWebAPITwitterListID)inListID withRange:(IRWebAPITwitterStatusIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

//	- (void) createOrUpdateList:(IRWebAPITwitterListID)inListID withName:(NSString *)inPromisedListName becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) createListWithName:(NSString *)inName description:(NSString *)inDescription becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) updateList:(IRWebAPITwitterListID)inListID withName:(NSString *)inName description:(NSString *)inDescription becomingPrivate:(BOOL)inListBecomesPrivate successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) deleteList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;


- (void) retrieveMembersOfList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) removeMember:(IRWebAPITwitterUserID)inUserID fromList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) addMember:(IRWebAPITwitterUserID)inUserID toList:(IRWebAPITwitterListID)inListID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

@end
