//
//  MLRemoteResourcesManager.h
//  Milk
//
//  Created by Evadne Wu on 12/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IRWebAPIKit.h"




#ifndef __MLRemoteResourcesManager__
#define __MLRemoteResourcesManager__

typedef void (^MLRemoteResourcesManagerCallback) (NSData *mappedCachedDataOrNil);

#define MLRemoteResourcesManagerDidRetrieveResourceNotification @"MLRemoteResourcesManagerDidRetrieveResourceNotification"

#endif





@interface IRRemoteResourcesManager : NSObject

+ (IRRemoteResourcesManager *) sharedManager;

- (void) clearCacheDirectory;

- (void) retrieveResourceAtRemoteURL:(NSURL *)inRemoteURL forceReload:(BOOL)inForceReload;

- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL skippingUncachedFile:(BOOL)inSkipsIO;
- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL;

//	Can return NSData* or nil, if the resource is not cached.
//	The latter calls inSkipsIO:YES


- (UIImage *) imageAtRemoteURL:(NSURL *)inRemoteURL;	//	Convenience wrapper around +resourceAtRemoteURL:

- (id) cachedResourceAtRemoteURL:(NSURL *)inRemoteURL;	//	Only returns NSData* if the resource is in a memory-backed cache

- (BOOL) hasStableResourceForRemoteURL:(NSURL *)inRemoteURL;	//	Returns YES if the file is downloaded, e.g. cached, and is not being redownloaded

- (NSURL *) downloadingResourceURLMatchingURL:(NSURL *)inRemoteURL;	//	Returns an NSURL that is being downloaded, useful when registering for notifications

@end
