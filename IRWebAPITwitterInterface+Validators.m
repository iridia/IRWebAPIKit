//
//  IRWebAPITwitterInterface+Validators.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Validators.h"


@implementation IRWebAPITwitterInterface (Validators)

- (IRWebAPIResposeValidator) defaultTimelineValidator {

	return [[(^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
		id response = [inResponseOrNil valueForKeyPath:@"response"];
		
		if (!response)
		return NO;
	
		if ([response isEqual:[NSNull null]])
		return NO;
	
		if (![response isKindOfClass:[NSArray class]])
		return NO;
		
		if ([(NSArray *)response count] > 0)
		if ([[[(NSArray *)response objectAtIndex:0] valueForKeyPath:@"text"] isEqual:[NSNull null]])
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

- (IRWebAPIResposeValidator) defaultListsValidator {

	return [[(^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
		
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

	return [[(^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
		if (![inResponseOrNil valueForKeyPath:@"text"])
		return NO;
		
		return YES;
	
	}) copy] autorelease];

}

- (IRWebAPIResposeValidator) defaultNoErrorValidator {

	return [[(^ (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil) {
	
		if ([inResponseOrNil isEqual:[NSNull null]])
		return NO;
	
		if ([inResponseOrNil valueForKeyPath:@"error"]) {
		
			NSLog(@"Fix Me: defaultNoErrorValidator: %@", [inResponseOrNil valueForKeyPath:@"error"]);
			
			return NO;
		
		}
		
		return YES;
	
	}) copy] autorelease];	

}

@end
