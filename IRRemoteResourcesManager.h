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





@class IRRemoteResourcesManager;
@protocol IRRemoteResourcesManagerDelegate <NSObject>

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didBeginDownloadingResourceAtURL:(NSURL *)anURL;
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFinishDownloadingResourceAtURL:(NSURL *)anURL;
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFailDownloadingResourceAtURL:(NSURL *)anURL;

@end





@interface IRRemoteResourcesManager : NSObject

+ (IRRemoteResourcesManager *) sharedManager;
- (void) retrieveResource:(NSURL *)resourceURL withCallback:(void(^)(NSData *returnedDataOrNil))aBlock;

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

@property (nonatomic, readwrite, assign) id<IRRemoteResourcesManagerDelegate> delegate;

@end
