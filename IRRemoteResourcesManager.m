//
//  IRRemoteResourcesManager.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRRemoteResourcesManager.h"
#import "IRRemoteResourceDownloadOperation.h"

NSString * const kIRRemoteResourcesManagerDidRetrieveResourceNotification = @"IRRemoteResourcesManagerDidRetrieveResourceNotification";


@interface IRRemoteResourcesManager () <NSCacheDelegate, IRRemoteResourceDownloadOperationDelegate>

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;
@property (nonatomic, readwrite, retain) NSMutableArray *enqueuedOperations;
- (void) enqueueOperationsIfNeeded;

@property (nonatomic, readwrite, assign) dispatch_queue_t operationQueue;
- (void) performInBackground:(void(^)(void))aBlock;
- (void) performOnMainThread:(void(^)(void))aBlock;

@property (nonatomic, readonly, retain) NSString *cacheDirectoryPath;
- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL;
- (BOOL) clearCacheDirectory;

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL;

@end


@implementation IRRemoteResourcesManager

@synthesize queue, operationQueue;
@synthesize enqueuedOperations;
@synthesize schedulingStrategy;

@synthesize delegate;
@synthesize cacheDirectoryPath;

@synthesize onRemoteResourceDownloadOperationWillBegin;

+ (IRRemoteResourcesManager *) sharedManager {

	static IRRemoteResourcesManager *sharedManagerInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManagerInstance = [[self alloc] init];
	});

	return sharedManagerInstance;

}

- (id) init {

	self = [super init];
	
	if (!self)
		return nil;
		
	schedulingStrategy = IRPostponeLowerPriorityOperationsStrategy;
		
	return self;

}

- (NSOperationQueue *) queue {

	if (queue)
		return queue;
	
	queue = [[NSOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	
	return queue;

}

- (dispatch_queue_t) operationQueue {

	if (operationQueue)
		return operationQueue;
	
	operationQueue = dispatch_queue_create("iridia.remoteResourcesManager.operationQueue", DISPATCH_QUEUE_SERIAL);
	return operationQueue;

}

- (NSMutableArray *) enqueuedOperations {

	if (enqueuedOperations)
		return enqueuedOperations;
	
	enqueuedOperations = [[NSMutableArray array] retain];
	return enqueuedOperations;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (operationQueue)
		dispatch_release(operationQueue);
	
	[queue release];
	[enqueuedOperations release];
	[cacheDirectoryPath release];
	
	[onRemoteResourceDownloadOperationWillBegin release];
		
	[super dealloc];

}

- (void) performInBackground:(void (^)(void))aBlock {

	dispatch_async(self.operationQueue, aBlock);

}

- (void) performOnMainThread:(void (^)(void))aBlock {

	if ([NSThread isMainThread])
		aBlock();
	else
		dispatch_async(dispatch_get_main_queue(), aBlock);

}

- (IRRemoteResourceDownloadOperation *) runningOperationForURL:(NSURL *)anURL {

	NSParameterAssert(anURL);

	NSArray *allMatches = [self.queue.operations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (IRRemoteResourceDownloadOperation *anOperation, NSDictionary *bindings) {
	
		return (BOOL)(![anOperation isCancelled] && [[anOperation.url absoluteString] isEqual:[anURL absoluteString]]);
		
	}]];
	
	NSParameterAssert([allMatches count] <= 1);
	
	return [allMatches lastObject];

}

- (IRRemoteResourceDownloadOperation *) enqueuedOperationForURL:(NSURL *)anURL {

	NSParameterAssert(anURL);

	NSArray *allMatches = [self.enqueuedOperations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (IRRemoteResourceDownloadOperation *anOperation, NSDictionary *bindings) {
	
		return [[anOperation.url absoluteString] isEqual:[anURL absoluteString]];
		
	}]];
	
	NSParameterAssert([allMatches count] <= 1);
	
	return [allMatches lastObject];

}

- (IRRemoteResourceDownloadOperation *) prospectiveOperationForURL:(NSURL *)anURL enqueue:(BOOL)enqueuesOperation {

	__block __typeof__(self) nrSelf = self;
	__block IRRemoteResourceDownloadOperation *operation = nil;
		
	operation = [IRRemoteResourceDownloadOperation operationWithURL:anURL path:[self pathForCachedContentsOfRemoteURL:anURL usedProspectiveURL:NULL] prelude: ^ {
	
		dispatch_async(dispatch_get_main_queue(), ^ {
			
			[nrSelf.delegate remoteResourcesManager:nrSelf didBeginDownloadingResourceAtURL:operation.url];
			
		});
		
	} completion: ^ {
	
		BOOL didFinish = !!(operation.path);
		NSString *operationPath = operation.path;
		NSURL *operationURL = operation.url;
		
		[operation retain];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (didFinish) {
			
				[operation invokeCompletionBlocks];
				[operation autorelease];
				
				[nrSelf notifyUpdatedResourceForRemoteURL:operationURL];
				[nrSelf.delegate remoteResourcesManager:nrSelf didFinishDownloadingResourceAtURL:operationURL];
			
			} else {

				[nrSelf.delegate remoteResourcesManager:nrSelf didFailDownloadingResourceAtURL:operationURL];
			
			}
			
			[nrSelf performInBackground: ^ {
				
				[nrSelf enqueueOperationsIfNeeded];
				
			}];
			
		});
		
	}];
	
	operation.delegate = self;
	
	if (enqueuesOperation)
		[self.enqueuedOperations insertObject:operation atIndex:0];
	
	return operation;

}

- (void) remoteResourceDownloadOperationWillBegin:(IRRemoteResourceDownloadOperation *)anOperation {

	if ([self.delegate respondsToSelector:@selector(remoteResourcesManager:invokedURLForResourceAtURL:)]) {
		NSMutableURLRequest *request = [anOperation underlyingRequest];
		request.URL = [self.delegate remoteResourcesManager:self invokedURLForResourceAtURL:request.URL];
	}
	
	if (self.onRemoteResourceDownloadOperationWillBegin)
		self.onRemoteResourceDownloadOperationWillBegin(anOperation);

}

- (void) retrieveResourceAtURL:(NSURL *)inRemoteURL withCompletionBlock:(void(^)(NSURL *tempFileURLOrNil))aBlock {

	[self retrieveResourceAtURL:inRemoteURL usingPriority:NSOperationQueuePriorityNormal forced:NO withCompletionBlock:aBlock];

}

- (void) retrieveResourceAtURL:(NSURL *)anURL usingPriority:(NSOperationQueuePriority)priority forced:(BOOL)forcesReload withCompletionBlock:(void(^)(NSURL *tempFileURLOrNil))aBlock {

	__block __typeof__(self) nrSelf = self;

	[nrSelf performInBackground: ^ {
	
		[self.queue setSuspended:YES];
	
		__block IRRemoteResourceDownloadOperation *operation = nil;
		BOOL operationRunning = NO, operationEnqueued = NO;
		
		void (^pounce)(NSURL *anURLOrNil) = ^ (NSURL *anURLOrNil) {
			if (aBlock)
				aBlock(anURLOrNil);
		};
		
		void (^stitch)(void) = ^ {
			
			if (!aBlock)
				return;
			
			[operation appendCompletionBlock: ^ {
				NSString *capturedPath = operation.path;
				[nrSelf performInBackground: ^ {
					pounce([NSURL fileURLWithPath:capturedPath]);
				}];
			}];
			
		};
	
		if ((!operation) && (operation = [self runningOperationForURL:anURL])) {
			operationRunning = !!operation;
		}
		
		if (operationRunning && forcesReload) {
			IRRemoteResourceDownloadOperation *cancelledOperation = operation;
			operation = [cancelledOperation continuationOperationCancellingCurrentOperation:YES];
			[self.enqueuedOperations insertObject:operation atIndex:0];
			operationRunning = NO;
			operationEnqueued = YES;
		}
		
		if ((!operation) && (operation = [self enqueuedOperationForURL:anURL])) {
			operationEnqueued = !!operation;
		}
		
		if (!operation) {
			
			operation = [self prospectiveOperationForURL:anURL enqueue:YES];
			operationEnqueued = !!operation;
			
		}
		
		[self.queue setSuspended:NO];
		
		if (!operation) {
			pounce(nil);
			return;
		}
		
		stitch();
		
		[self enqueueOperationsIfNeeded];
				
	}];

}

- (void) enqueueOperationsIfNeeded {

	NSComparator operationQueuePriorityComparator = (NSComparator) ^ (NSOperation *lhs, NSOperation *rhs) {
		return (lhs.queuePriority < rhs.queuePriority) ? NSOrderedDescending :
			(lhs.queuePriority == rhs.queuePriority) ? NSOrderedSame :
			(lhs.queuePriority > rhs.queuePriority) ? NSOrderedAscending : NSOrderedSame;
	};
	
	NSArray * (^sorted)(NSArray *) = ^ (NSArray *anArray) {
		return [anArray sortedArrayUsingComparator:operationQueuePriorityComparator];
	};
	
	NSArray * (^filtered)(NSArray *, BOOL(^)(id, NSDictionary *)) = ^ (NSArray *filteredArray, BOOL(^predicate)(id evaluatedObject, NSDictionary *bindings)) {
		return [filteredArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:predicate]];
	};
	
	NSArray *usableCurrentOperations = filtered(self.queue.operations, ^ (NSOperation *anOperation, NSDictionary *bindings){
		return (BOOL)![anOperation isCancelled];
	});
	
	NSArray *usableEnqueuedOperations = filtered(self.enqueuedOperations, ^ (NSOperation *anOperation, NSDictionary *bindings){
		return (BOOL)![anOperation isCancelled];
	});
	
	for (NSOperation *anOperation in usableCurrentOperations)
		NSParameterAssert(![anOperation isCancelled]);
	
	NSArray *sortedCurrentOperations = sorted(self.queue.operations);
	NSArray *sortedEnqueuedOperations = sorted(usableEnqueuedOperations);
	NSArray *sortedAllOperations = sorted([sortedCurrentOperations arrayByAddingObjectsFromArray:sortedEnqueuedOperations]);
	
	NSArray *legitimateOperations = [sortedAllOperations objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){
		0, MIN(self.queue.maxConcurrentOperationCount, [sortedAllOperations count])
	}]];
	
	NSArray *insertedOperations = filtered(legitimateOperations, ^ (id evaluatedObject, NSDictionary *bindings) {
		return (BOOL)![sortedCurrentOperations containsObject:evaluatedObject];			
	});
	
	NSArray *postponedOperations = filtered(sortedCurrentOperations, ^ (id evaluatedObject, NSDictionary *bindings) {
		return (BOOL)![legitimateOperations containsObject:evaluatedObject];
	});
	
	for (NSOperation *anOperation in insertedOperations)
	if (![self.queue.operations containsObject:anOperation])
			[self.queue addOperation:anOperation];
	
	[self.enqueuedOperations removeObjectsInArray:insertedOperations];
	
	[postponedOperations enumerateObjectsUsingBlock: ^ (IRRemoteResourceDownloadOperation *anOperation, NSUInteger idx, BOOL *stop) {
		[self.enqueuedOperations addObject:[anOperation continuationOperationCancellingCurrentOperation:YES]];
	}];

}


- (NSString *) cacheDirectoryPath {

	if (cacheDirectoryPath)
		return cacheDirectoryPath;
		
	NSString *prospectivePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass([self class])];
	
	NSError *cacheDirectoryCreationError;	
	if (![[NSFileManager defaultManager] createDirectoryAtPath:prospectivePath withIntermediateDirectories:YES attributes:nil error:&cacheDirectoryCreationError]) {
		NSLog(@"Error occurred while creating or assuring cache directory: %@", cacheDirectoryCreationError);
		return nil;
	}
	
	cacheDirectoryPath = [prospectivePath retain];
	return cacheDirectoryPath;

}

- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL {

	return [[self cacheDirectoryPath] stringByAppendingPathComponent:IRWebAPIKitNonce()];

}

- (BOOL) clearCacheDirectory {

	NSError *error;
	BOOL didClear = [[NSFileManager defaultManager] removeItemAtPath:[self cacheDirectoryPath] error:&error];
	if (!didClear)
		NSLog(@"Error occurred while removing the cache directory; %@", error);
	
	return didClear;

}

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL {

	inRemoteURL = [[inRemoteURL copy] autorelease];
	
	dispatch_async(dispatch_get_main_queue(), ^ {

		[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:kIRRemoteResourcesManagerDidRetrieveResourceNotification object:inRemoteURL] postingStyle:NSPostASAP coalesceMask:NSNotificationNoCoalescing forModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSRunLoopCommonModes, nil]];
	
	});

}

@end


@implementation IRRemoteResourcesManager (ImageLoading)

- (void) retrieveImageAtURL:(NSURL *)inRemoteURL forced:(BOOL)forcesReload withCompletionBlock:(void(^)(IRRemoteResourcesManagerImage *tempImage))aBlock {

	[self retrieveResourceAtURL:inRemoteURL usingPriority:NSOperationQueuePriorityNormal forced:forcesReload withCompletionBlock:^(NSURL *tempFileURLOrNil) {
		
		if (!tempFileURLOrNil)
			return;
			
		#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		
			if (aBlock)
				aBlock([UIImage imageWithContentsOfFile:[tempFileURLOrNil path]]);
			
		#else
		
			NSParameterAssert(NO);
			
		#endif
		
	}];

}

@end
