//
//  IRWebAPITwitterInterface+User.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 4/5/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"


@interface IRWebAPITwitterInterface (User)

- (void) retrieveMetadataForUserWithIdentifiers:(NSArray *)identifiers withSuccessHandler:(IRWebAPIInterfaceCallback)successBlock failureHandler:(IRWebAPIInterfaceCallback)failureBlock;

- (void) retrieveMetadataForUser:(IRWebAPITwitterUserID)anUserID withSuccessHandler:(IRWebAPIInterfaceCallback)successBlock failureHandler:(IRWebAPIInterfaceCallback)failureBlock;

@end
