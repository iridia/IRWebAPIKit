//
//  IRRemoteResourcesManager.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#import <UIKit/UIKit.h>
	#define IRRemoteResourcesManagerImage UIImage
#else
	#import <Cocoa/Cocoa.h>
	#define IRRemoteResourcesManagerImage NSImage
#endif

enum {
  IRFirstInFirstOutStragery = 0,
  IRPostponeLowerPriorityOperationsStrategy,
}; typedef NSUInteger IRSchedulingStrategy;


@class IRRemoteResourcesManager;
@protocol IRRemoteResourcesManagerDelegate <NSObject>

- (void) remoteResourcesManager:(IRRemoteResourcesManager *)manager didBeginDownloadingResourceAtURL:(NSURL *)anURL;
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)manager didFinishDownloadingResourceAtURL:(NSURL *)anURL;
- (void) remoteResourcesManager:(IRRemoteResourcesManager *)manager didFailDownloadingResourceAtURL:(NSURL *)anURL;

@end


@interface IRRemoteResourcesManager : NSObject

+ (IRRemoteResourcesManager *) sharedManager;

@property (nonatomic, readonly, retain) NSOperationQueue *queue;
@property (nonatomic, readwrite, assign) id<IRRemoteResourcesManagerDelegate> delegate;

- (void) retrieveResourceAtURL:(NSURL *)inRemoteURL withCompletionBlock:(void(^)(NSURL *tempFileURLOrNil))aBlock;
- (void) retrieveResourceAtURL:(NSURL *)inRemoteURL usingPriority:(NSOperationQueuePriority)priority forced:(BOOL)forcesReload withCompletionBlock:(void(^)(NSURL *tempFileURLOrNil))aBlock;
@property (nonatomic, readwrite, assign) IRSchedulingStrategy schedulingStrategy;	//	Defaults to IRPostponeLowerPriorityOperationsStrategy

@end




@interface IRRemoteResourcesManager (ImageLoading)

- (void) retrieveImageAtURL:(NSURL *)inRemoteURL forced:(BOOL)forcesReload withCompletionBlock:(void(^)(IRRemoteResourcesManagerImage *tempImage))aBlock;

@end
