//
//  IRWebAPIInterfaceXOAuthAuthenticating.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@class IRWebAPIXOAuthAuthenticator;
@protocol IRWebAPIInterfaceXOAuthAuthenticating <IRWebAPIInterfaceAuthenticating>

@property (nonatomic, readonly, retain) IRWebAPIXOAuthAuthenticator *authenticator;

@property (nonatomic, readwrite, retain) NSString *consumerKey;
@property (nonatomic, readwrite, retain) NSString *consumerSecret;

@end
