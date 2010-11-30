//
//  IRWebAPIInterfaceXOAuthInterfaceProtocol.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@protocol IRWebAPIInterfaceXOAuthInterfaceProtocol

- (void) setConsumerKey:(NSString *)inConsumerKey;
- (NSString *) consumerKey;
- (void) setConsumerSecret:(NSString *)inConsumerSecret;
- (NSString *) consumerSecret;

@end
