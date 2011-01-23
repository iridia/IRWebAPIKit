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
	NSURL *fileURL = [NSURL fileURLWithPath:[preferredCacheDirectoryPath stringByAppendingPathComponent:IRWebAPIKitNonce()]];
	
	if (![[NSFileManager defaultManager] createFileAtPath:[fileURL path] contents:nil attributes:nil]) {
	
		NSLog(@"Error creating file at URL %@", fileURL);
		return nil;
	
	}
	
	return fileURL;
	
}


+ (BOOL) cleanUpTemporaryFileAtURL:(NSURL *)inTemporaryFileURL {

	NSError *error;

	if (![[NSFileManager defaultManager] removeItemAtURL:inTemporaryFileURL error:&error]) {
	
		NSLog(@"Error removing file at URL %@", inTemporaryFileURL);
		return NO;
	
	}
	
	return YES;

}


+ (IRWebAPIResponseContextTransformer) defaultCleanUpTemporaryFilesRequestTransformer {

	return [[(^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
	
		NSArray *cachedFileURLs = [inResponseContext objectForKey:kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^ {
		
			if (cachedFileURLs)
			for (NSURL *aFileURL in cachedFileURLs)
			[self cleanUpTemporaryFileAtURL:aFileURL];
	
		});

		return inParsedResponse;
	
	}) copy] autorelease];

}

@end
