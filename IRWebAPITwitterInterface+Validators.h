//
//  IRWebAPITwitterInterface+Validators.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"

@interface IRWebAPITwitterInterface (Validators)

- (IRWebAPIResposeValidator) defaultNoErrorValidator;

//	Makes sure the response is 200 and does not come with an error


- (IRWebAPIResposeValidator) defaultValidatorForArrayNamed:(NSString *)inKeyPathToResponseArray withElementKeyPaths:(NSArray *)inKeyPaths validator:(BOOL(^)(id aKeyPath, id currentObject))inValidator;

- (IRWebAPIResposeValidator) defaultValidatorForArrayNamed:(NSString *)inKeyPathToResponseArray withElementKeyPaths:(NSArray *)inKeyPaths;

//	Makes sure that the key path inKeyPathToResponseArray points to an NSArray, and each element in that array has values described in inKeyPaths
//	The default validator is a “non-nil” validator.


- (IRWebAPIResposeValidator) defaultExistingValueValidatorForKeyPaths:(NSArray *)inKeyPaths;

//	return [self defaultValidatorForArrayNamed:@"response" withElementKeyPaths:inKeyPaths];


- (IRWebAPIResposeValidator) defaultTimelineValidator;
- (IRWebAPIResposeValidator) defaultSingleTweetValidator;

- (IRWebAPIResposeValidator) defaultListsValidator;

@end
