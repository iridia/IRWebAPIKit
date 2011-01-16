//
//  IRWebAPITwitterInterface+Validators.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"

@interface IRWebAPITwitterInterface (Validators)

- (IRWebAPIResposeValidator) defaultTimelineValidator;
- (IRWebAPIResposeValidator) defaultSingleTweetValidator;
- (IRWebAPIResposeValidator) defaultNoErrorValidator;

- (IRWebAPIResposeValidator) defaultListsValidator;

@end
