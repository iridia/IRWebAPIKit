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

@property (nonatomic, readwrite, assign) NSInteger operationQueueSuspendingCount;
- (BOOL) isSuspendingOperationQueue;

- (void) beginSuspendingOperationQueue;
- (void) endSuspendingOperationQueue;

@property (nonatomic, readonly, retain) NSMutableDictionary *allOperations;
@property (nonatomic, readonly, assign) dispatch_queue_t allOperationsQueue;
- (IRRemoteResourceDownloadOperation *) operationWithURL:(NSURL *)anURL;
- (BOOL) addOperation:(IRRemoteResourceDownloadOperation *)anOperation;
- (BOOL) removeOperation:(IRRemoteResourceDownloadOperation *)anOperation;

@end


@implementation IRRemoteResourcesManager

@synthesize queue, operationQueue;
@synthesize enqueuedOperations;
@synthesize schedulingStrategy;

@synthesize delegate;
@synthesize cacheDirectoryPath;

@synthesize onRemoteResourceDownloadOperationWillBegin;

@synthesize allOperations, allOperationsQueue;

@synthesize operationQueueSuspendingCount;

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
	queue = [[NSOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	operationQueue = dispatch_queue_create("iridia.remoteResourcesManager.operationQueue", DISPATCH_QUEUE_SERIAL);
	enqueuedOperations = [[NSMutableArray array] retain];
	
	allOperations = [[NSMutableDictionary dictionary] retain];
	allOperationsQueue = dispatch_queue_create("iridia.remoteResourcesManager.operationsManagingQueue", DISPATCH_QUEUE_SERIAL);
		
	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (operationQueue)
		dispatch_release(operationQueue);
	
	[queue release];
	[enqueuedOperations release];
	[cacheDirectoryPath release];
	
	[onRemoteResourceDownloadOperationWillBegin release];
	
	[allOperations release];
	
	if (allOperationsQueue)
		dispatch_release(allOperationsQueue);
		
	[super dealloc];

}





- (NSInteger) operationQueueSuspendingCount {

	NSParameterAssert([NSThread isMainThread]);
	return operationQueueSuspendingCount;

}

- (void) setOperationQueueSuspendingCount:(NSInteger)newOperationQueueSuspendingCount {

	NSParameterAssert([NSThread isMainThread]);
	
	if (operationQueueSuspendingCount == newOperationQueueSuspendingCount)
		return;
	
	[self willChangeValueForKey:@"operationQueueSuspendingCount"];
	
	if ((operationQueueSuspendingCount == 0) && (newOperationQueueSuspendingCount == 1)) {
	
		NSParameterAssert(![self.queue isSuspended]);
		[self.queue setSuspended:YES];
	
	} else if ((operationQueueSuspendingCount == 1) && (newOperationQueueSuspendingCount == 0)) {
	
		NSParameterAssert([self.queue isSuspended]);
		[self.queue setSuspended:NO];
	
	}
	
	operationQueueSuspendingCount = newOperationQueueSuspendingCount;
	
	[self didChangeValueForKey:@"operationQueueSuspendingCount"];

}

- (BOOL) isSuspendingOperationQueue {

	return (BOOL)!!self.operationQueueSuspendingCount;

}

- (void) beginSuspendingOperationQueue {

	NSParameterAssert([NSThread isMainThread]);
	
	self.operationQueueSuspendingCount++;

}

- (void) endSuspendingOperationQueue {

	NSParameterAssert([NSThread isMainThread]);
	NSParameterAssert(self.operationQueueSuspendingCount > 0);
	
	self.operationQueueSuspendingCount--;

}





- (IRRemoteResourceDownloadOperation *) operationWithURL:(NSURL *)anURL {

	NSParameterAssert(dispatch_get_current_queue() != self.allOperationsQueue);
	
	__block IRRemoteResourceDownloadOperation *returnedOperation = nil;

	dispatch_sync(self.allOperationsQueue, ^ {
		returnedOperation = [self.allOperations objectForKey:[anURL absoluteString]];
	});
	
	return returnedOperation;

}

- (BOOL) addOperation:(IRRemoteResourceDownloadOperation *)anOperation {

	NSParameterAssert(dispatch_get_current_queue() != self.allOperationsQueue);
	
	__block BOOL didAdd = NO;
	
	dispatch_sync(self.allOperationsQueue, ^{
	
		NSString *key = [anOperation.url absoluteString];
	
		if ([self.allOperations objectForKey:key]) {
			return;
		}
		
		[self.allOperations setObject:anOperation forKey:key];
		
		didAdd = YES;
		
	});
	
	return didAdd;

}

- (BOOL) removeOperation:(IRRemoteResourceDownloadOperation *)anOperation {

	NSParameterAssert(dispatch_get_current_queue() != self.allOperationsQueue);
	
	__block BOOL didRemove = NO;

	dispatch_sync(self.allOperationsQueue, ^ {
	
		NSString *key = [anOperation.url absoluteString];
	
		if (![self.allOperations objectForKey:key])
			return;
		
		[self.allOperations removeObjectForKey:key];
		
		didRemove = YES;
		
	});
	
	return didRemove;

}





- (void) performInBackground:(void (^)(void))aBlock {

	dispatch_async(self.operationQueue, aBlock);

}

- (void) performOnMainThread:(void (^)(void))aBlock {

	NSParameterAssert(![NSThread isMainThread]);
	
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
	
		[nrSelf.delegate remoteResourcesManager:nrSelf didBeginDownloadingResourceAtURL:operation.url];
		
	} completion: ^ {
	
		BOOL didFinish = !!(operation.path);
		NSString *operationPath = operation.path;
		NSURL *operationURL = operation.url;
		
		if (didFinish) {
		
			[operation retain];
		
			dispatch_async(dispatch_get_main_queue(), ^ {
	
				[operation invokeCompletionBlocks];
				[operation autorelease];
				
				[nrSelf notifyUpdatedResourceForRemoteURL:operationURL];
				[nrSelf.delegate remoteResourcesManager:nrSelf didFinishDownloadingResourceAtURL:operationURL];
			
			});
		
		} else {

			dispatch_async(dispatch_get_main_queue(), ^ {
	
				[nrSelf.delegate remoteResourcesManager:nrSelf didFailDownloadingResourceAtURL:operationURL];
			
			});
		
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			[nrSelf beginSuspendingOperationQueue];
			
			[nrSelf performInBackground: ^ {
			
				[nrSelf enqueueOperationsIfNeeded];

				dispatch_async(dispatch_get_main_queue(), ^{
				
					[nrSelf endSuspendingOperationQueue];
				
				});
				
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

	if (![NSThread isMainThread]) {
	
		NSParameterAssert(NO);
	
	}

	__block __typeof__(self) nrSelf = self;
	
	[nrSelf performInBackground: ^ {
	
		__block IRRemoteResourceDownloadOperation *operation = [self operationWithURL:anURL];
		
		if (!operation) {
			
			operation = [self prospectiveOperationForURL:anURL enqueue:YES];
			operation.queuePriority = priority;
			
			[nrSelf addOperation:operation];
			[operation appendCompletionBlock:^{
				[nrSelf removeOperation:operation];
			}];
						
		} else {
		
			if (forcesReload && [nrSelf.queue.operations containsObject:operation]) {
			
				operation = [operation continuationOperationCancellingCurrentOperation:YES];
				operation.queuePriority = priority;
				
				[nrSelf addOperation:operation];
				[operation appendCompletionBlock:^{
					[nrSelf removeOperation:operation];
				}];
			
			}
		
		}
		
		if (aBlock) {
		
			[operation appendCompletionBlock: ^ {
				
				NSString *capturedPath = operation.path;
				[nrSelf performInBackground: ^ {
				
					aBlock([NSURL fileURLWithPath:capturedPath]);
					
				}];
				
			}];
			
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{

			[self beginSuspendingOperationQueue];
			
			[nrSelf performInBackground:^{
				
				[self enqueueOperationsIfNeeded];
				
				dispatch_async(dispatch_get_main_queue(), ^{

					[self endSuspendingOperationQueue];
					
				});

			}];
					
		});
						
	}];

}

- (void) enqueueOperationsIfNeeded {

	NSParameterAssert([self.queue isSuspended]);

	@autoreleasepool {
			 
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
