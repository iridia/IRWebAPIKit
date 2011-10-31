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
NSString * const kIRRemoteResourcesManagerFilePath = @"kIRRemoteResourcesManagerFilePath";


@interface IRRemoteResourcesManager () <NSCacheDelegate>

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;

@property (nonatomic, readwrite, assign) dispatch_queue_t operationQueue;
- (void) performInBackground:(void(^)(void))aBlock;
- (void) performOnMainThread:(void(^)(void))aBlock;

@property (nonatomic, readwrite, retain) NSMutableArray *enqueuedOperations;

- (void) enqueueURLForDownload:(NSURL *)enqueuedURL;
- (void) enqueueOperationsIfNeeded;

@property (nonatomic, readwrite, retain) NSCache *cache;
@property (nonatomic, readonly, retain) NSString *cacheDirectoryPath;
@property (nonatomic, readonly, retain) NSString *cacheRegistryPath;

- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL;

- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL;

- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL;
- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL usedEnqueuedOperations:(NSArray **)matchingOperations;

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL;

@end


@implementation IRRemoteResourcesManager

@synthesize queue, operationQueue;
@synthesize enqueuedOperations;
@synthesize schedulingStrategy;

@synthesize cache, delegate;
@synthesize cacheDirectoryPath, cacheRegistryPath;

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
	[cache release];
	//	[cacheRegistry release];
	[cacheDirectoryPath release];
	[cacheRegistryPath release];
		
	[super dealloc];

}





- (void) performInBackground:(void (^)(void))aBlock {

	NSLog(@"performing on operation queue %x", (unsigned int)self.operationQueue);
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
	
		return [[anOperation.url absoluteString] isEqual:[anURL absoluteString]];
		
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
				
				//	[nrSelf.cacheRegistry setObject:operationPath forKey:[operationURL absoluteString]];		
				
				[nrSelf notifyUpdatedResourceForRemoteURL:operationURL];
				[nrSelf.delegate remoteResourcesManager:nrSelf didFinishDownloadingResourceAtURL:operationURL];
			
			} else {

				[nrSelf.delegate remoteResourcesManager:nrSelf didFailDownloadingResourceAtURL:operationURL];
			
			}
			
			[nrSelf performInBackground:^{

				[nrSelf enqueueOperationsIfNeeded];
				
			}];
			
		});
		
	}];
	
	NSLog(@"%s: %@ returning %@; enqueues? %x", __PRETTY_FUNCTION__, self, operation, enqueuesOperation);
	
	if (enqueuesOperation)
		[self.enqueuedOperations insertObject:operation atIndex:0];
	
	return operation;

}

- (void) retrieveResourceAtURL:(NSURL *)inRemoteURL withCompletionBlock:(void(^)(NSURL *tempFileURLOrNil))aBlock {

	[self retrieveResourceAtURL:inRemoteURL usingPriority:NSOperationQueuePriorityNormal forced:NO withCompletionBlock:aBlock];

}

- (void) retrieveResourceAtURL:(NSURL *)anURL usingPriority:(NSOperationQueuePriority)priority forced:(BOOL)forcesReload withCompletionBlock:(void(^)(NSURL *tempFileURLOrNil))aBlock {

	__block __typeof__(self) nrSelf = self;

	[nrSelf performInBackground: ^ {
	
		__block IRRemoteResourceDownloadOperation *operation = nil;
		BOOL operationRunning = NO, operationEnqueued = NO;
		
		void (^pounce)(NSURL *anURLOrNil) = ^ (NSURL *anURLOrNil) {
			if (aBlock)
				aBlock(anURLOrNil);
		};
		
		void (^stitch)(void) = ^ {
			[operation appendCompletionBlock: ^ {
				NSString *capturedPath = operation.path;
				[nrSelf performInBackground: ^ {
					pounce([NSURL fileURLWithPath:capturedPath]);
				}];
			}];
		};
	
		if ((!operation) && (operation = [self runningOperationForURL:anURL]))
			operationRunning = !!operation;
		
		if (operationRunning && forcesReload) {
			IRRemoteResourceDownloadOperation *cancelledOperation = operation;
			operation = [cancelledOperation continuationOperationCancellingCurrentOperation:YES];
			[self.enqueuedOperations insertObject:operation atIndex:0];
			operationRunning = NO;
			operationEnqueued = YES;
		}
		
		if ((!operation) && (operation = [self enqueuedOperationForURL:anURL]))
			operationEnqueued = !!operation;
		
		if (!operation) {
		
			operation = [self prospectiveOperationForURL:anURL enqueue:YES];
			
			if (operation)
				operationEnqueued = YES;
		
		}
		
		if (!operation) {
			pounce(nil);
			return;
		}
		
		stitch();
		
		[self enqueueOperationsIfNeeded];
				
	}];

}

- (void) enqueueOperationsIfNeeded {

		NSComparator operationQueuePriorityComparator =  ^ (NSOperation *lhs, NSOperation *rhs) {
			return (lhs.queuePriority < rhs.queuePriority) ? NSOrderedAscending :
				(lhs.queuePriority == rhs.queuePriority) ? NSOrderedSame :
				(lhs.queuePriority > rhs.queuePriority) ? NSOrderedDescending : NSOrderedSame;
		};
		
		NSArray * (^sorted)(NSArray *) = ^ (NSArray *anArray) {
			return [anArray sortedArrayUsingComparator:operationQueuePriorityComparator];
		};
		
		NSArray * (^filtered)(NSArray *, BOOL(^)(id, NSDictionary *)) = ^ (NSArray *filteredArray, BOOL(^predicate)(id evaluatedObject, NSDictionary *bindings)) {
			return [filteredArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:predicate]];
		};
		
		for (NSOperation *anOperation in self.queue.operations)
			NSParameterAssert(![anOperation isCancelled]);
		
		NSArray *sortedCurrentOperations = sorted(self.queue.operations);
		NSArray *sortedEnqueuedOperations = sorted(self.enqueuedOperations);
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
		
		NSLog(@"Queue operations are now: %@", self.queue.operations);
		NSLog(@"Enqueued operations are now: %@", self.enqueuedOperations);
		NSLog(@"--");
		
//	}];

	return;
	
	if (self.queue.operationCount >= self.queue.maxConcurrentOperationCount)
		return;
	
	NSUInteger blottedOperationCount = MIN([self.enqueuedOperations count], (self.queue.maxConcurrentOperationCount - self.queue.operationCount));
	if (!blottedOperationCount)
		return;
	
	NSArray *movedOperations = [self.enqueuedOperations objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, blottedOperationCount }]];
	
	[self.enqueuedOperations removeObjectsInArray:movedOperations];
	[self.queue addOperations:movedOperations waitUntilFinished:NO];

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

- (NSString *) cacheRegistryPath {

	if (!cacheRegistryPath)
		cacheRegistryPath = [[[self cacheDirectoryPath] stringByAppendingPathComponent:@"cacheRegistry"] retain];
	
	return cacheRegistryPath;

}

//	- (NSMutableDictionary *) cacheRegistry {
//
//		if (!cacheRegistry) {
//		
//			NSString *ownCacheRegistryPath = [self cacheRegistryPath];
//		
//			if ([[NSFileManager defaultManager] fileExistsAtPath:ownCacheRegistryPath])
//				cacheRegistry = [[NSMutableDictionary dictionaryWithContentsOfFile:ownCacheRegistryPath] retain];
//			else
//				cacheRegistry = [[NSMutableDictionary dictionary] retain];
//			
//		}
//		
//		return cacheRegistry;
//
//	}

- (void) handleDidReceiveMemoryWarningNotification:(NSNotification *)aNotification {

	[self.cache removeAllObjects];

}

- (void) handleWillResignActive:(NSNotification *)aNotification {

	//	[self persistCacheRegistry];

}

- (void) handleWillTerminate:(NSNotification *)aNotification {

	//	[self persistCacheRegistry];

}


- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL {

//	NSString *existingPath = [self.cacheRegistry objectForKey:[inRemoteURL absoluteString]];
//	
//	if (existingPath) {
//		
//		if (returnedProspectiveURL)
//			*returnedProspectiveURL = NO;
//		
//		return existingPath;
//		
//	}
//	
//	if (returnedProspectiveURL)
//			*returnedProspectiveURL = YES;
	
	return [[self cacheDirectoryPath] stringByAppendingPathComponent:IRWebAPIKitNonce()];

}

- (void) clearCacheDirectory {

	NSError *error;
	if (![[NSFileManager defaultManager] removeItemAtPath:[self cacheDirectoryPath] error:&error])
		NSLog(@"Error occurred while removing the cache directory; %@", error);

}

- (BOOL) persistCacheRegistry {

	return NO;

	//	return [self.cacheRegistry writeToFile:[self cacheRegistryPath] atomically:YES];

}

- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL {

	return !![self.cache objectForKey:[inRemoteURL absoluteString]];
	
}

- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL {

	return [self isDownloadingResourceFromRemoteURL:inRemoteURL usedEnqueuedOperations:nil];

}

- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL usedEnqueuedOperations:(NSArray **)matchingOperations {

	NSPredicate *predicate = [NSPredicate predicateWithBlock: ^ (IRRemoteResourceDownloadOperation *operation, NSDictionary *bindings) {
		return [[operation.url absoluteString] isEqual:[inRemoteURL absoluteString]];
	}];

	NSParameterAssert(inRemoteURL);
	NSArray *operationsWorking = [[[self.queue.operations mutableCopy] autorelease] filteredArrayUsingPredicate:predicate];
	NSArray *operationsEnqueued = [[[self.enqueuedOperations mutableCopy] autorelease] filteredArrayUsingPredicate:predicate];
	
	if (matchingOperations)
		*matchingOperations = operationsEnqueued;
	
	return !!([operationsWorking count] + [operationsEnqueued count]);

}

- (void) retrieveResourceAtRemoteURL:(NSURL *)inRemoteURL forceReload:(BOOL)inForceReload {

	if (!inRemoteURL)
		return;
	
	if (!inForceReload)
	if ([self.cache objectForKey:[inRemoteURL absoluteString]] || [self hasCachedResourceForRemoteURL:inRemoteURL])
		return;
	
	[self enqueueURLForDownload:inRemoteURL];
	
}


- (void) enqueueURLForDownload:(NSURL *)enqueuedURL {

//	NSArray *enqueued = nil;
//	if ([self isDownloadingResourceFromRemoteURL:enqueuedURL usedEnqueuedOperations:&enqueued]) {
//	
//		[self.enqueuedOperations removeObjectsInArray:enqueued];
//		[self.enqueuedOperations insertObjects:enqueued atIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, [enqueued count] }]];
//		return;
//		
//	}
//	
//	NSString *oldFilePath = [self.cacheRegistry objectForKey:[enqueuedURL absoluteString]];
//	
//	if (oldFilePath) {
//		[[NSFileManager defaultManager] removeItemAtPath:oldFilePath error:nil];
//		[self.cacheRegistry removeObjectForKey:[enqueuedURL absoluteString]];
//		[self.cache removeObjectForKey:[enqueuedURL absoluteString]];
//	}
//
//	__block IRRemoteResourceDownloadOperation *operation;
//	operation = [IRRemoteResourceDownloadOperation operationWithURL:enqueuedURL path:[self pathForCachedContentsOfRemoteURL:enqueuedURL usedProspectiveURL:NULL] prelude: ^ {
//	
//		dispatch_async(dispatch_get_main_queue(), ^ {
//			
//			[self.delegate remoteResourcesManager:self didBeginDownloadingResourceAtURL:operation.url];
//			
//		});
//		
//	} completion: ^ {
//	
//		BOOL didFinish = !!(operation.path);
//		NSString *operationPath = operation.path;
//		NSURL *operationURL = operation.url;
//		
//		dispatch_async(dispatch_get_main_queue(), ^ {
//		
//			if (didFinish) {
//			
//				//	[self.cacheRegistry setObject:operationPath forKey:[operationURL absoluteString]];		
//				[self notifyUpdatedResourceForRemoteURL:operationURL];
//				[self.delegate remoteResourcesManager:self didFinishDownloadingResourceAtURL:operationURL];
//			
//			} else {
//
//				[self.delegate remoteResourcesManager:self didFailDownloadingResourceAtURL:operationURL];
//			
//			}
//			
//			[self enqueueOperationsIfNeeded];
//		
//		});
//		
//	}];
//	
//	[self.enqueuedOperations addObject:operation];
//	[self enqueueOperationsIfNeeded];

}

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL {

	inRemoteURL = [[inRemoteURL copy] autorelease];
	
	dispatch_async(dispatch_get_main_queue(), ^ {

		[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:kIRRemoteResourcesManagerDidRetrieveResourceNotification object:inRemoteURL] postingStyle:NSPostASAP coalesceMask:NSNotificationNoCoalescing forModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSRunLoopCommonModes, nil]];
	
	});

}

//	- (BOOL) hasStableResourceForRemoteURL:(NSURL *)inRemoteURL {
//
//		if ([self hasCachedResourceForRemoteURL:inRemoteURL])
//			return YES;
//		
//		if ([self isDownloadingResourceFromRemoteURL:inRemoteURL])
//			return NO;
//		
//		if ([self.cacheRegistry objectForKey:[inRemoteURL absoluteString]])
//			return YES;
//		
//		return NO;
//		
//	}

- (id) cachedResourceAtRemoteURL:(NSURL *)inRemoteURL {

	return [self.cache objectForKey:[inRemoteURL absoluteString]];

}

- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL skippingUncachedFile:(BOOL)inSkipsIO {

	return nil;

	//	id cachedObjectOrNil = [self cachedResourceAtRemoteURL:inRemoteURL];
	//	if (!cachedObjectOrNil || ([cachedObjectOrNil length] == 0)) {
	//		
	//		if (inSkipsIO)
	//			return nil;
	//		
	//		if (![self hasStableResourceForRemoteURL:inRemoteURL])
	//			return nil;
	//		
	//		id cacheKey = [inRemoteURL absoluteString];
	//		[self.cache removeObjectForKey:cacheKey];
	//		
	//		BOOL isProspectivePath = NO;
	//		NSString *filePath = [self pathForCachedContentsOfRemoteURL:inRemoteURL usedProspectiveURL:&isProspectivePath];
	//		NSParameterAssert(filePath && !isProspectivePath);
	//		
	//		NSPurgeableData *purgableCachedData = [NSPurgeableData dataWithContentsOfMappedFile:filePath];
	//		NSParameterAssert(purgableCachedData);
	//		
	//		[self.cache setObject:purgableCachedData forKey:[inRemoteURL absoluteString] cost:[purgableCachedData length]];
	//		
	//		//	Even though the object could have been cached, it might NOT be cached at all
	//		return purgableCachedData;
	//	
	//	}
	//
	//	NSParameterAssert(cachedObjectOrNil);
	//	return cachedObjectOrNil;

}


- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL {

	return [self resourceAtRemoteURL:inRemoteURL skippingUncachedFile:YES];

}


- (void) retrieveResource:(NSURL *)resourceURL withCallback:(void(^)(NSData *returnedDataOrNil))aBlock {
	
	NSData *probableData = [self resourceAtRemoteURL:resourceURL skippingUncachedFile:NO];

	if (probableData && [probableData length]) {

		if (aBlock)
			aBlock(probableData);

		return;

	}
	
	__block id opaqueReference = [[[NSNotificationCenter defaultCenter] addObserverForName:kIRRemoteResourcesManagerDidRetrieveResourceNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
		
		NSURL *incomingURL = (NSURL *)[notification object];
		
		if (![[incomingURL absoluteString] isEqual:[resourceURL absoluteString]])
			return;
	
		NSData *ensuredData = [self resourceAtRemoteURL:incomingURL skippingUncachedFile:NO];
		NSParameterAssert(ensuredData);

		if (aBlock)
			aBlock(ensuredData);

		[[NSNotificationCenter defaultCenter] removeObserver:opaqueReference];
		[opaqueReference autorelease];
	
	}] retain];
	
	if (![self isDownloadingResourceFromRemoteURL:resourceURL])
		[self retrieveResourceAtRemoteURL:resourceURL forceReload:YES];

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
