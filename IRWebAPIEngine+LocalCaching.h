//
//  IRWebAPIEngine+LocalCaching.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine.h"


extern NSString * const kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey;

@interface IRWebAPIEngine (LocalCaching)

+ (NSURL *) newTemporaryFileURL NS_RETURNS_RETAINED;
+ (BOOL) cleanUpTemporaryFileAtURL:(NSURL *)inTemporaryFileURL;
+ (IRWebAPIResponseContextTransformer) defaultCleanUpTemporaryFilesResponseTransformer;

@end
