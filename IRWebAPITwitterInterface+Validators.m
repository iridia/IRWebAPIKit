//
//  IRWebAPITwitterInterface+Validators.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@implementation IRWebAPITwitterInterface (Validators)

- (IRWebAPIResposeValidator) defaultNoErrorValidator {

	return [IRWebAPIInterface defaultNoErrorValidator];

}

- (IRWebAPIResposeValidator) defaultValidatorForArrayNamed:(NSString *)inKeyPathToResponseArray withElementKeyPaths:(NSArray *)inKeyPaths validator:(BOOL(^)(id aKeyPath, id currentObject))inValidator {

	return [[(^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if (![self defaultNoErrorValidator](inResponseOrNil, inResponseContext))
		return NO;
		
		NSArray *responseArray = [inResponseOrNil valueForKeyPath:inKeyPathToResponseArray];
		if (![responseArray isKindOfClass:[NSArray class]])
		return NO;
		
		for (id anObject in responseArray)
		for (id aKeyPath in inKeyPaths)
		if (!inValidator(aKeyPath, [anObject valueForKeyPath:aKeyPath]))
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

- (IRWebAPIResposeValidator) defaultValidatorForArrayNamed:(NSString *)inKeyPathToResponseArray withElementKeyPaths:(NSArray *)inKeyPaths {

	return [self defaultValidatorForArrayNamed:inKeyPathToResponseArray withElementKeyPaths:inKeyPaths validator: ^ (id aKeyPath, id currentObject) {
	
		return (BOOL)(currentObject != nil);
	
	}];

}


- (IRWebAPIResposeValidator) defaultExistingValueValidatorForKeyPaths:(NSArray *)inKeyPaths {

	return [self defaultValidatorForArrayNamed:@"response" withElementKeyPaths:inKeyPaths];

}

- (IRWebAPIResposeValidator) defaultTimelineValidator {

	return [[(^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if (![self defaultExistingValueValidatorForKeyPaths:[NSArray arrayWithObject:@"response"]])
		return NO;

		id response = [inResponseOrNil valueForKeyPath:@"response"];
		
		if (!response || ![response isKindOfClass:[NSArray class]])
		return NO;
		
		if ([(NSArray *)response count] > 0)
		if ([[[(NSArray *)response objectAtIndex:0] valueForKeyPath:@"text"] isEqual:[NSNull null]])
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

- (IRWebAPIResposeValidator) defaultListsValidator {

	return [[(^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
		
		if (![self defaultNoErrorValidator](inResponseOrNil, inResponseContext))
		return NO;

		id response = [inResponseOrNil valueForKeyPath:@"response"];
		
		if (!response)
		return NO;
	
		if ([response isEqual:[NSNull null]])
		return NO;
	
		if (![response isKindOfClass:[NSArray class]])
		return NO;
		
		if ([(NSArray *)response count] > 0)
		if ([[[(NSArray *)response objectAtIndex:0] valueForKeyPath:@"name"] isEqual:[NSNull null]])
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

- (IRWebAPIResposeValidator) defaultSingleTweetValidator {

	return [[(^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		if (![self defaultNoErrorValidator](inResponseOrNil, inResponseContext))
		return NO;
	
		if (![inResponseOrNil valueForKeyPath:@"text"])
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

@end
