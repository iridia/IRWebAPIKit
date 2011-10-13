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
@property (nonatomic, readwrite, retain) NSMutableArray *enqueuedOperations;

- (void) enqueueURLForDownload:(NSURL *)enqueuedURL;
- (void) enqueueOperationsIfNeeded;

@property (nonatomic, readwrite, retain) NSCache *cache;
@property (nonatomic, readonly, retain) NSString *cacheDirectoryPath;
@property (nonatomic, readonly, retain) NSString *cacheRegistryPath;

@property (nonatomic, readwrite, retain) NSMutableDictionary *cacheRegistry;
- (BOOL) persistCacheRegistry;

- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL;

- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL;

- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL;
- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL usedEnqueuedOperations:(NSArray **)matchingOperations;

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL;

@end


@implementation IRRemoteResourcesManager

@synthesize queue, enqueuedOperations;
@synthesize cache, delegate;
@synthesize cacheRegistry, cacheDirectoryPath, cacheRegistryPath;

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
		
	queue = [[NSOperationQueue alloc] init];
	queue.maxConcurrentOperationCount = 1;
	
	enqueuedOperations = [[NSMutableArray array] retain];
	
	cache = [[NSCache alloc] init];
	cache.delegate = self;
	cache.totalCostLimit = 1024 * 1024 * 5;	//	1024 Bs * 1024 KBs * 5
	
	NSError *cacheDirectoryCreationError;	
	if (![[NSFileManager defaultManager] createDirectoryAtPath:[self cacheDirectoryPath] withIntermediateDirectories:YES attributes:nil error:&cacheDirectoryCreationError]) {
		NSLog(@"Error occurred while creating or assuring cache directory: %@", cacheDirectoryCreationError);
	};
	
	#if TARGET_OS_IPHONE
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	
	#endif
		
	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[queue release];
	[enqueuedOperations release];
	[cache release];
	[cacheRegistry release];
	[cacheDirectoryPath release];
	[cacheRegistryPath release];
		
	[super dealloc];

}


- (NSString *) cacheDirectoryPath {

	if (!cacheDirectoryPath)
		cacheDirectoryPath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass([self class])] retain];
	
	return cacheDirectoryPath;

}

- (NSString *) cacheRegistryPath {

	if (!cacheRegistryPath)
		cacheRegistryPath = [[[self cacheDirectoryPath] stringByAppendingPathComponent:@"cacheRegistry"] retain];
	
	return cacheRegistryPath;

}

- (NSMutableDictionary *) cacheRegistry {

	if (!cacheRegistry) {
	
		NSString *ownCacheRegistryPath = [self cacheRegistryPath];
	
		if ([[NSFileManager defaultManager] fileExistsAtPath:ownCacheRegistryPath])
			cacheRegistry = [[NSMutableDictionary dictionaryWithContentsOfFile:ownCacheRegistryPath] retain];
		else
			cacheRegistry = [[NSMutableDictionary dictionary] retain];
		
	}
	
	return cacheRegistry;

}

- (void) handleDidReceiveMemoryWarningNotification:(NSNotification *)aNotification {

	[self.cache removeAllObjects];

}

- (void) handleWillResignActive:(NSNotification *)aNotification {

	[self persistCacheRegistry];

}

- (void) handleWillTerminate:(NSNotification *)aNotification {

	[self persistCacheRegistry];

}


- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL {

	NSString *existingPath = [self.cacheRegistry objectForKey:[inRemoteURL absoluteString]];
	
	if (existingPath) {
		
		if (returnedProspectiveURL)
			*returnedProspectiveURL = NO;
		
		return existingPath;
		
	}
	
	if (returnedProspectiveURL)
			*returnedProspectiveURL = YES;
	
	return [[self cacheDirectoryPath] stringByAppendingPathComponent:IRWebAPIKitNonce()];

}

- (void) clearCacheDirectory {

	NSError *error;
	if (![[NSFileManager defaultManager] removeItemAtPath:[self cacheDirectoryPath] error:&error])
		NSLog(@"Error occurred while removing the cache directory; %@", error);

}

- (BOOL) persistCacheRegistry {

	return [self.cacheRegistry writeToFile:[self cacheRegistryPath] atomically:YES];

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

	NSArray *enqueued = nil;
	if ([self isDownloadingResourceFromRemoteURL:enqueuedURL usedEnqueuedOperations:&enqueued]) {
	
		[self.enqueuedOperations removeObjectsInArray:enqueued];
		[self.enqueuedOperations insertObjects:enqueued atIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, [enqueued count] }]];
		return;
		
	}
	
	NSString *oldFilePath = [self.cacheRegistry objectForKey:[	enqueuedURL absoluteString]];
	
	if (oldFilePath) {
		[[NSFileManager defaultManager] removeItemAtPath:oldFilePath error:nil];
		[self.cacheRegistry removeObjectForKey:[enqueuedURL absoluteString]];
		[self.cache removeObjectForKey:[enqueuedURL absoluteString]];
	}

	__block IRRemoteResourceDownloadOperation *operation;
	operation = [IRRemoteResourceDownloadOperation operationWithURL:enqueuedURL path:[self pathForCachedContentsOfRemoteURL:enqueuedURL usedProspectiveURL:NULL] prelude: ^ {
	
		dispatch_async(dispatch_get_main_queue(), ^ {
			
			[self.delegate remoteResourcesManager:self didBeginDownloadingResourceAtURL:operation.url];
			
		});
		
	} completion: ^ {
	
		BOOL didFinish = !!(operation.path);
		NSString *operationPath = operation.path;
		NSURL *operationURL = operation.url;
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			if (didFinish) {
			
				[self.cacheRegistry setObject:operationPath forKey:[operationURL absoluteString]];		
				[self notifyUpdatedResourceForRemoteURL:operationURL];
				[self.delegate remoteResourcesManager:self didFinishDownloadingResourceAtURL:operationURL];
			
			} else {

				[self.delegate remoteResourcesManager:self didFailDownloadingResourceAtURL:operationURL];
			
			}
			
			[self enqueueOperationsIfNeeded];
		
		});
		
	}];
	
	[self.enqueuedOperations addObject:operation];
	[self enqueueOperationsIfNeeded];

}

- (void) enqueueOperationsIfNeeded {

	if (self.queue.operationCount >= self.queue.maxConcurrentOperationCount)
		return;
	
	NSUInteger blottedOperationCount = MIN([self.enqueuedOperations count], (self.queue.maxConcurrentOperationCount - self.queue.operationCount));
	if (!blottedOperationCount)
		return;
	
	NSArray *movedOperations = [self.enqueuedOperations objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){ 0, blottedOperationCount }]];
	
	[self.enqueuedOperations removeObjectsInArray:movedOperations];
	[self.queue addOperations:movedOperations waitUntilFinished:NO];

}

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL {

	inRemoteURL = [[inRemoteURL copy] autorelease];
	
	dispatch_async(dispatch_get_main_queue(), ^ {

		[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:kIRRemoteResourcesManagerDidRetrieveResourceNotification object:inRemoteURL] postingStyle:NSPostNow coalesceMask:NSNotificationNoCoalescing forModes:nil];
	
	});

}

- (BOOL) hasStableResourceForRemoteURL:(NSURL *)inRemoteURL {

	if ([self hasCachedResourceForRemoteURL:inRemoteURL])
		return YES;
	
	if ([self isDownloadingResourceFromRemoteURL:inRemoteURL])
		return NO;
	
	if ([self.cacheRegistry objectForKey:[inRemoteURL absoluteString]])
		return YES;
	
	return NO;
	
}

- (id) cachedResourceAtRemoteURL:(NSURL *)inRemoteURL {

	return [self.cache objectForKey:[inRemoteURL absoluteString]];

}

- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL skippingUncachedFile:(BOOL)inSkipsIO {

	id cachedObjectOrNil = [self cachedResourceAtRemoteURL:inRemoteURL];
	if (!cachedObjectOrNil || ([cachedObjectOrNil length] == 0)) {
		
		if (inSkipsIO)
			return nil;
		
		if (![self hasStableResourceForRemoteURL:inRemoteURL])
			return nil;
		
		id cacheKey = [inRemoteURL absoluteString];
		[self.cache removeObjectForKey:cacheKey];
		
		BOOL isProspectivePath = NO;
		NSString *filePath = [self pathForCachedContentsOfRemoteURL:inRemoteURL usedProspectiveURL:&isProspectivePath];
		NSParameterAssert(filePath && !isProspectivePath);
		
		NSPurgeableData *purgableCachedData = [NSPurgeableData dataWithContentsOfMappedFile:filePath];
		NSParameterAssert(purgableCachedData);
		
		[self.cache setObject:purgableCachedData forKey:[inRemoteURL absoluteString] cost:[purgableCachedData length]];
		
		//	Even though the object could have been cached, it might NOT be cached at all
		return purgableCachedData;
	
	}

	NSParameterAssert(cachedObjectOrNil);
	return cachedObjectOrNil;

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

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

- (UIImage *) imageAtRemoteURL:(NSURL *)inRemoteURL {

	NSData *imageData = [self resourceAtRemoteURL:inRemoteURL];
		
	if (!imageData)
		return nil;
	
	UIImage *returnedImage = [UIImage imageWithData:[self resourceAtRemoteURL:inRemoteURL]];
	
	if (returnedImage)
		return returnedImage;
	
	[self retrieveResourceAtRemoteURL:inRemoteURL forceReload:YES];
	return nil;

}

#endif

@end
