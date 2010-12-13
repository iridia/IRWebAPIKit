//
//  IRWebAPITwitterInterface.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

@interface IRWebAPITwitterInterface : IRWebAPIInterface <IRWebAPIInterfaceAuthenticating, IRWebAPIInterfaceXOAuthAuthenticating>

- (void) updateStatusForCurrentUserWithContents:(NSString *)inContents userinfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPICallback)inSuccessCallback onFailure:(IRWebAPICallback)inFailureCallback;

@end
