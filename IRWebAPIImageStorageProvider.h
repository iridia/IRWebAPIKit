//
//  IRWebAPIImageStorageProviderInterface.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

@class UIImage;

@protocol IRWebAPIImageStorageProvider

- (void) uploadImageAtURL:(NSURL *)inImageURL onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback;


@optional

- (void) uploadImage:(UIImage *)inImage onProgress:(void(^)(float inProgressRatio))inProgressCallback onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback;

- (void) uploadImageAtURL:(NSURL *)inImageURL onProgress:(void(^)(float inProgressRatio))inProgressCallback onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback;

//	Progress Ratio is between 0 to 1

@end
