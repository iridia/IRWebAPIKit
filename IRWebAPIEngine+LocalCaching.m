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


NSString * const kIRWebAPIEngineLocallocalCacheDirectoryPath = @"kIRWebAPIEngineLocalCachingBasePath";

@interface IRWebAPIEngine (LocalCachingPrivate)

@property (nonatomic, readonly, retain) NSString *localCacheDirectoryPath;

@end

@implementation IRWebAPIEngine (LocalCachingPrivate)

- (NSString *) localCacheDirectoryPath {

	NSString *aPath = objc_getAssociatedObject(self, kIRWebAPIEngineLocallocalCacheDirectoryPath);
	
	if (!aPath) {
	
		NSString *applicationCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *preferredCacheDirectoryPath = [applicationCacheDirectory stringByAppendingPathComponent:NSStringFromClass([self class])];
		
		objc_setAssociatedObject(self, kIRWebAPIEngineLocallocalCacheDirectoryPath, preferredCacheDirectoryPath, OBJC_ASSOCIATION_RETAIN);
		
	}
	
	return aPath;

}

@end





@implementation IRWebAPIEngine (LocalCaching)

- (NSURL *) temporaryFileURL {

	NSURL *fileURL = [NSURL fileURLWithPath:[self.localCacheDirectoryPath stringByAppendingPathComponent:IRWebAPIKitNonce()]];
	
	if (![[NSFileManager defaultManager] createFileAtPath:[fileURL path] contents:nil attributes:nil]) {
	
		NSLog(@"Error creating file at URL %@", fileURL);
		return nil;
	
	}
	
	return fileURL;
	
}


- (BOOL) cleanUpTemporaryFileAtURL:(NSURL *)inTemporaryFileURL {

	NSError *error;

	if (![[NSFileManager defaultManager] removeItemAtURL:inTemporaryFileURL error:&error]) {
	
		NSLog(@"Error removing file at URL %@", inTemporaryFileURL);
		return NO;
	
	}
	
	return YES;

}


+ (IRWebAPIResponseContextTransformer) defaultCleanUpTemporaryFilesRequestTransformer {

	return [[(^ (NSDictionary *inParsedResponse, NSDictionary *inResponseContext) {
	
		NSAssert(NO, @"Implement!");
	
		return inParsedResponse;
	
	}) copy] autorelease];

}

@end
