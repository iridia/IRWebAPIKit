//
//  IRRemoteResourcesManager.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRRemoteResourcesManager.h"


NSString * const kIRRemoteResourcesManagerDidRetrieveResourceNotification = @"IRRemoteResourcesManagerDidRetrieveResourceNotification";
NSString * const kIRRemoteResourcesManagerFilePath = @"kIRRemoteResourcesManagerFilePath";


@interface IRRemoteResourceDownloadOperation : NSOperation

+ (IRRemoteResourceDownloadOperation *) operationWithURL:(NSURL *)aRemoteURL path:(NSString *)aLocalPath prelude:(void(^)(void))aPrelude completion:(void(^)(void))aBlock;

@property (nonatomic, readonly, retain) NSString *path;
@property (nonatomic, readonly, retain) NSURL *url;
@property (nonatomic, readonly, assign) long long processedBytes;
@property (nonatomic, readonly, assign) long long totalBytes;
@property (nonatomic, readonly, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, readonly, assign, getter=isFinished) BOOL finished;
@property (nonatomic, readonly, assign) float_t progress; // Convenience

@end


@interface IRRemoteResourceDownloadOperation ()

@property (nonatomic, readwrite, retain) NSString *path;
@property (nonatomic, readwrite, retain) NSURL *url;
@property (nonatomic, readwrite, assign) long long processedBytes;
@property (nonatomic, readwrite, assign) long long totalBytes;
@property (nonatomic, readwrite, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, assign, getter=isFinished) BOOL finished;
@property (nonatomic, readwrite, retain) NSFileHandle *fileHandle;
@property (nonatomic, readwrite, retain) NSURLConnection *connection;

@property (nonatomic, readwrite, assign) dispatch_queue_t actualDispatchQueue;

- (void) onMainQueue:(void(^)(void))aBlock;
- (void) onOriginalQueue:(void(^)(void))aBlock;

@property (nonatomic, readwrite, copy) void(^onMain)(void);

@end


@implementation IRRemoteResourceDownloadOperation

@synthesize path, url, processedBytes, totalBytes, executing, finished;
@synthesize fileHandle, connection;
@synthesize actualDispatchQueue;
@synthesize onMain;

+ (IRRemoteResourceDownloadOperation *) operationWithURL:(NSURL *)aRemoteURL path:(NSString *)aLocalPath prelude:(void(^)(void))aPrelude completion:(void(^)(void))aBlock {

	IRRemoteResourceDownloadOperation *returnedOperation = [[[self alloc] init] autorelease];
	returnedOperation.url = aRemoteURL;
	returnedOperation.path = aLocalPath;
	returnedOperation.onMain = aPrelude;
	returnedOperation.completionBlock = aBlock;
	return returnedOperation;

}

- (void) dealloc {

	[path release];
	[url release];
	[fileHandle release];
	
	__block NSURLConnection *nrConnection = connection;
	dispatch_async(dispatch_get_main_queue(), ^ {
		[nrConnection release];
	});
	
	[onMain release];
	
	[super dealloc];

}

- (void) onMainQueue:(void(^)(void))aBlock {
	
	self.actualDispatchQueue = dispatch_get_current_queue();
	dispatch_async(dispatch_get_main_queue(), ^ {
		aBlock();
	});
	
}

- (void) onOriginalQueue:(void(^)(void))aBlock {

	dispatch_async(self.actualDispatchQueue, aBlock);
	
}

- (void) start {

	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
		return;
	}

	if ([self isCancelled]) {
		self.finished = YES;
		return;
	}
	
	self.executing = YES;
	[self main];

}

- (void) main {

	NSParameterAssert(self.url);
	NSParameterAssert(self.path);
	
	if (self.onMain)
		self.onMain();
	
	[[NSFileManager defaultManager] createFileAtPath:self.path contents:nil attributes:nil];
	self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.path];
	NSParameterAssert(self.fileHandle);
	
	[self onMainQueue: ^ {
		self.connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10] delegate:self];
		//	[self.connection start];
	}];
	
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

	[self onOriginalQueue: ^ {

		self.totalBytes = response.expectedContentLength;
		
	}];

}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

	[self onOriginalQueue: ^ {
	
		self.processedBytes += [data length];
		[self.fileHandle writeData:data];
	
	}];

}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {

	[self onOriginalQueue: ^ {
	
		[self.fileHandle closeFile];
		
		self.executing = NO;
		self.finished = YES;
	
	}];

}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	[self onOriginalQueue: ^ {
	
		[self.fileHandle closeFile];
		
		[[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
		self.path = nil;
		
		self.executing = NO;
		self.finished = YES;
	
	}];

}

- (BOOL) isConcurrent {

	return YES;

}

- (float_t) progress {

	if (!totalBytes)
		return 0.0f;
	
	return (float_t)((double_t)processedBytes / (double_t)totalBytes);

}

- (void) setFinished:(BOOL)newFinished {

	if (newFinished == finished)
		return;
	
	[self willChangeValueForKey:@"isFinished"];
	finished = newFinished;
	[self didChangeValueForKey:@"isFinished"];

}

- (void) setExecuting:(BOOL)newExecuting {

	if (newExecuting == executing)
		return;
	
	[self willChangeValueForKey:@"isExecuting"];
	executing = newExecuting;
	[self didChangeValueForKey:@"isExecuting"];

}

@end




@interface IRRemoteResourcesManager () <NSCacheDelegate>

@property (nonatomic, readwrite, retain) NSOperationQueue *queue;

- (void) enqueueURLForDownload:(NSURL *)enqueuedURL;

@property (nonatomic, readwrite, retain) NSCache *cache;
@property (nonatomic, readonly, retain) NSString *cacheDirectoryPath;
@property (nonatomic, readonly, retain) NSString *cacheRegistryPath;

@property (nonatomic, readwrite, retain) NSMutableDictionary *cacheRegistry;
- (BOOL) persistCacheRegistry;

- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL usedProspectiveURL:(BOOL *)returnedProspectiveURL;

- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL;
- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL;
- (void) createFileHandlerAssociatedWithNewURLRequestForRemoteURL:(NSURL *)inRemoteURL;
- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL;

@end


@implementation IRRemoteResourcesManager

@synthesize queue, cache, delegate;
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
	
	cache = [[NSCache alloc] init];
	cache.delegate = self;
	cache.totalCostLimit = 1024 * 1024 * 5;	//	1024 Bs * 1024 KBs * 5
	
	NSError *cacheDirectoryCreationError;	
	if (![[NSFileManager defaultManager] createDirectoryAtPath:[self cacheDirectoryPath] withIntermediateDirectories:YES attributes:nil error:&cacheDirectoryCreationError]) {
		NSLog(@"Error occurred while creating or assuring cache directory: %@", cacheDirectoryCreationError);
	};
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		
	return self;

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

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[queue release];
	[cache release];
	[cacheRegistry release];
	[cacheDirectoryPath release];
	[cacheRegistryPath release];
		
	[super dealloc];

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

	return !![[[[self.queue.operations copy] autorelease] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IRRemoteResourceDownloadOperation *operation, NSDictionary *bindings) {
	
		return [[operation.url absoluteString] isEqual:[inRemoteURL absoluteString]];
		
	}]] count];

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

	if ([self isDownloadingResourceFromRemoteURL:enqueuedURL])
		return;

	NSString *oldFilePath = [self.cacheRegistry objectForKey:[enqueuedURL absoluteString]];
	
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
		
		});
		
	}];
	
	[self.queue addOperation:operation];

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
		
		if (inSkipsIO) {
			return nil;
		}
		
		id cacheKey = [inRemoteURL absoluteString];
		[self.cache removeObjectForKey:cacheKey];
	
		if (![self hasStableResourceForRemoteURL:inRemoteURL]) {
			return nil;
		}
		
		
		BOOL isProspectivePath = NO;
		NSString *filePath = [self pathForCachedContentsOfRemoteURL:inRemoteURL usedProspectiveURL:&isProspectivePath];
		
		NSParameterAssert(filePath && !isProspectivePath);
		NSPurgeableData *purgableCachedData = [NSPurgeableData dataWithContentsOfMappedFile:filePath];
		
		[self.cache setObject:purgableCachedData forKey:[inRemoteURL absoluteString] cost:[purgableCachedData length]];
		
		NSData *returnedCachedResource = [self cachedResourceAtRemoteURL:inRemoteURL];
		NSParameterAssert(returnedCachedResource);
		return returnedCachedResource;
	
	}

	NSParameterAssert(cachedObjectOrNil);
	return cachedObjectOrNil;

}

- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL {

	return [self resourceAtRemoteURL:inRemoteURL skippingUncachedFile:YES];

}

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
