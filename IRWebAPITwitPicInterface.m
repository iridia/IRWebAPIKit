//
//  IRWebAPITwitPicInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitPicInterface.h"


@implementation IRWebAPITwitPicInterface

- (void) uploadImageAtURL:(NSURL *)inImageURL onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {

	if (!self.apiKey) {
	
		NSLog(@"%@: No API Key.", self);
	
		if (inFailureCallback)
		inFailureCallback(nil, NO, NO);
		
		return;
	
	}
	
	NSAssert(NO, @"Implement!");

}

@end
