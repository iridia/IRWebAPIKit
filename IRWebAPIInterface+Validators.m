//
//  IRWebAPIInterface+Validators.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/29/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@implementation IRWebAPIInterface (Validators)

+ (IRWebAPIResposeValidator) defaultNoErrorValidator {

	return [[(^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		NSHTTPURLResponse *response = (NSHTTPURLResponse *)[inResponseContext objectForKey:kIRWebAPIEngineResponseContextURLResponse];
	
		BOOL noError = ([response statusCode] == 200);
	
		if (!noError) {
			
			IRWebAPIKitLog(@"Error: %x %@", [response statusCode], [[response class] localizedStringForStatusCode:[response statusCode]]);
			
			if ([inResponseOrNil isEqual:[NSNull null]]) {
				
				return NO;
				
			}
			
			id errorContent = nil;
			if ((errorContent = [inResponseOrNil valueForKeyPath:@"error"])) {
				
				IRWebAPIKitLog(@"Error from Server: %@", errorContent);
				
			}

			return NO;
		
		}
	
		return YES;
	
	}) copy] autorelease];	

}

@end
