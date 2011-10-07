//
//  IRWebAPIEngine+LocalCaching.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>

#import "IRWebAPIEngine+LocalCaching.h"
#import "IRWebAPIHelpers.h"


NSString * const kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey = @"kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey";
NSString * const kIRWebAPIEngineLocallocalCacheDirectoryPath = @"kIRWebAPIEngineLocalCachingBasePath";





@implementation IRWebAPIEngine (LocalCaching)

+ (NSURL *) newTemporaryFileURL {

	NSString *applicationCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *preferredCacheDirectoryPath = [applicationCacheDirectory stringByAppendingPathComponent:NSStringFromClass([self class])];
	
	NSError *error;
	if (![[NSFileManager defaultManager] createDirectoryAtPath:preferredCacheDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
	
		NSLog(@"Erorr occurred while assuring cache directory existence: %@", error);
		return nil;
	
	};
	
	NSURL *fileURL = [[NSURL fileURLWithPath:[preferredCacheDirectoryPath stringByAppendingPathComponent:IRWebAPIKitNonce()]] retain];	
	return fileURL;
	
}


+ (BOOL) cleanUpTemporaryFileAtURL:(NSURL *)inTemporaryFileURL {

	NSError *error;
	
	if (![[NSFileManager defaultManager] removeItemAtURL:inTemporaryFileURL error:&error]) {
	
		NSLog(@"Error removing file at URL %@: %@", inTemporaryFileURL, error);
		return NO;
	
	} else {
	
		NSLog(@"Removed %@", inTemporaryFileURL);
	
	}
	
	return YES;

}


+ (IRWebAPIResponseContextTransformer) defaultCleanUpTemporaryFilesResponseTransformer {

	return [[(^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
	
		NSArray *cachedFileURLs = [[inResponseContext objectForKey:kIRWebAPIEngineResponseContextOriginalRequestContextName] objectForKey:kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey];
		
	//	DISPATCH_QUEUE_PRIORITY_BACKGROUND is unrecognized by LLVM 2.0 so we’re using the number it uses
		dispatch_async(dispatch_get_global_queue(-2, 0), ^ {
		
			if (cachedFileURLs)
			for (NSURL *aFileURL in cachedFileURLs)
			[self cleanUpTemporaryFileAtURL:aFileURL];
	
		});

		return inParsedResponse;
	
	}) copy] autorelease];

}

@end
