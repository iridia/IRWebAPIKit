//
//  IRRemoteResourcesManager.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IRWebAPIKit.h"


#ifndef __IRRemoteResourcesManager__
#define __IRRemoteResourcesManager__

typedef void (^IRRemoteResourcesManagerCallback) (NSData *mappedCachedDataOrNil);
extern NSString * const kIRRemoteResourcesManagerDidRetrieveResourceNotification;

#endif


@class IRRemoteResourcesManager;
@protocol IRRemoteResourcesManagerDelegate <NSObject>

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didBeginDownloadingResourceAtURL:(NSURL *)anURL;
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFinishDownloadingResourceAtURL:(NSURL *)anURL;
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)managed didFailDownloadingResourceAtURL:(NSURL *)anURL;

@end


@interface IRRemoteResourcesManager : NSObject

+ (IRRemoteResourcesManager *) sharedManager;

@property (nonatomic, readwrite, assign) NSUInteger maximumNumberOfConnections;
@property (nonatomic, readwrite, assign) id<IRRemoteResourcesManagerDelegate> delegate;

- (void) clearCacheDirectory;
- (void) retrieveResourceAtRemoteURL:(NSURL *)inRemoteURL forceReload:(BOOL)inForceReload;
- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL skippingUncachedFile:(BOOL)inSkipsIO;
- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL;
- (UIImage *) imageAtRemoteURL:(NSURL *)inRemoteURL;
- (id) cachedResourceAtRemoteURL:(NSURL *)inRemoteURL;
- (BOOL) hasStableResourceForRemoteURL:(NSURL *)inRemoteURL;
- (NSURL *) downloadingResourceURLMatchingURL:(NSURL *)inRemoteURL;

@end
