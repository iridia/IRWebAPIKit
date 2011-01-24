//
//  IRWebAPIInterfaceOAuthEchoReliance.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@protocol IRWebAPIInterfaceOAuthEchoReliance

@property (nonatomic, readwrite, retain) IRWebAPIInterface<IRWebAPIInterfaceXOAuthAuthenticating> *authenticatingInterface;

@end
