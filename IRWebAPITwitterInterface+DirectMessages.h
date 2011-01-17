//
//  IRWebAPITwitterInterface+DirectMessages.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/18/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"





@interface IRWebAPITwitterInterface (DirectMessages)

- (void) retrieveIncomingDirectMessagesWithRange:(IRWebAPITwitterDirectMessageIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) retrieveOutgoingDirectMessagesWithRange:(IRWebAPITwitterDirectMessageIDRange)inRange successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) sendDirectMessageToUser:(IRWebAPITwitterUserID)inUserID withContents:(NSString *)inContents successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) deleteDirectMessageWithID:(IRWebAPITwitterDirectMessageID)inMessageID successHandler:(IRWebAPIInterfaceCallback)inSuccessCallback failureHandler:(IRWebAPIInterfaceCallback)inFailureCallback;

@end
