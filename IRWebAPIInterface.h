//
//  IRWebAPIInterface.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"





@class IRWebAPIEngine, IRWebAPIAuthenticator, IRWebAPIContext;

@interface IRWebAPIInterface : NSObject

@property (nonatomic, readonly) IRWebAPIEngine *engine;
@property (nonatomic, readonly) IRWebAPIAuthenticator *authenticator;

- (id) initWithEngine:(IRWebAPIEngine *)inEngine authenticator:(IRWebAPIAuthenticator *)inAuthenticator;

@end




