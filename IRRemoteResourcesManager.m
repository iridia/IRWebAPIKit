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


@interface IRRemoteResourcesManager () <NSCacheDelegate>

@property (readwrite, retain) NSMutableArray *queuedURLs;
- (void) enqueueURLForDownload:(NSURL *)enqueuedURL;

@property (readwrite, retain) NSMutableSet *downloadingURLs;
@property (nonatomic, readwrite, retain) NSString *cacheDirectoryPath;
@property (nonatomic, readonly, assign) dispatch_queue_t fileHandleDispatchQueue;
@property (nonatomic, readwrite, assign) CFMutableDictionaryRef connectionsToRemoteURLs;
@property (nonatomic, readwrite, assign) CFMutableDictionaryRef connectionsToFileHandles;

@property (nonatomic, readwrite, retain) NSCache *cache;
@property (readwrite, retain) NSMutableDictionary *cachedURLsToFilePaths;

- (void) initializeCacheDirectoryAndRefreshCachedURLs;
- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL;
- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL;
- (void) createFileHandlerAssociatedWithNewURLRequestForRemoteURL:(NSURL *)inRemoteURL;
- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL;

- (BOOL) persistCacheRegistry;

@end





@implementation IRRemoteResourcesManager

@synthesize fileHandleDispatchQueue, queuedURLs, cachedURLsToFilePaths, downloadingURLs, cacheDirectoryPath, connectionsToRemoteURLs, connectionsToFileHandles, cache, maximumNumberOfConnections, delegate;

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
	
	fileHandleDispatchQueue = dispatch_queue_create("com.iridia.irwebapikit.remoteResourcesManager", NULL);
	
	self.queuedURLs = [NSMutableArray array];
	self.cachedURLsToFilePaths = [NSMutableDictionary dictionary];
	self.downloadingURLs = [NSMutableSet set];
	self.maximumNumberOfConnections = 10;
	
	self.connectionsToRemoteURLs = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	self.connectionsToFileHandles = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	self.cacheDirectoryPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:NSStringFromClass([self class])];
	
	self.cache = [[[NSCache alloc] init] autorelease];
	self.cache.delegate = self;
	self.cache.totalCostLimit = 1024 * 1024 * 5;	//	1024 Bs * 1024 KBs * 5
	
	[self initializeCacheDirectoryAndRefreshCachedURLs];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
		
	return self;

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

	dispatch_release(fileHandleDispatchQueue);
	
	[queuedURLs release];
	[cachedURLsToFilePaths release];
	[downloadingURLs release];
	
	CFRelease(connectionsToRemoteURLs);
	CFRelease(connectionsToFileHandles);
	
	[cacheDirectoryPath release];
	[cache release];
		
	[super dealloc];

}


- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL {

	NSString *existingPath = [self.cachedURLsToFilePaths objectForKey:[inRemoteURL absoluteString]];
	
	if (existingPath)
		return existingPath;
	
	return [[self cacheDirectoryPath] stringByAppendingPathComponent:IRWebAPIKitNonce()];

}

- (NSURL *) urlForCachedContentWithName:(NSString *)inName {

	return [NSURL URLWithString:IRWebAPIKitRFC3986DecodedStringMake(inName)];

}

- (void) clearCacheDirectory {

	NSError *error;
	if (![[NSFileManager defaultManager] removeItemAtPath:[self cacheDirectoryPath] error:&error])
		NSLog(@"Error occurred while removing the cache directory; %@", error);

}

- (void) initializeCacheDirectoryAndRefreshCachedURLs {
	
	NSError *error;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cachePath = [self cacheDirectoryPath];

	if (![fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error]) {
		NSLog(@"Error occurred while creating or assuring cache directory: %@", error);
		return;	
	};
	
	NSString *cacheRegistryPath = [cachePath stringByAppendingPathComponent:@"cacheRegistry"];
	if ([fileManager fileExistsAtPath:cacheRegistryPath]) {
		self.cachedURLsToFilePaths = [NSDictionary dictionaryWithContentsOfFile:cacheRegistryPath];
	}
	
}

- (BOOL) persistCacheRegistry {

	return [self.cachedURLsToFilePaths writeToFile:[[self cacheDirectoryPath] stringByAppendingPathComponent:@"cacheRegistry"] atomically:YES];

}





- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL {
	
	return (BOOL)!!([[[self.cachedURLsToFilePaths allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isEqual:[inRemoteURL absoluteString]];
	}]] count]);

}

- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL {

	return ([[[[self.downloadingURLs copy] autorelease] objectsPassingTest: ^ (id obj, BOOL *stop) {
	
		BOOL equals = [[obj absoluteURL] isEqual:[inRemoteURL absoluteURL]];
		
		*stop = equals;	
		return equals;
	
	}] count] > 0);

}

- (NSURL *) downloadingResourceURLMatchingURL:(NSURL *)inRemoteURL {

	return [[[[self.downloadingURLs copy] autorelease] objectsPassingTest:^(id obj, BOOL *stop) {
		
		return [[obj absoluteURL] isEqual:inRemoteURL];
		
	}] anyObject];

}





- (void) retrieveResourceAtRemoteURL:(NSURL *)inRemoteURL forceReload:(BOOL)inForceReload {

	if (!inRemoteURL)
		return;
	
	if (!inForceReload)
	if ([self.cache objectForKey:[inRemoteURL absoluteString]] || [self hasCachedResourceForRemoteURL:inRemoteURL]) {
	
		[self notifyUpdatedResourceForRemoteURL:inRemoteURL];
		return;
	
	}
	
	if (![self isDownloadingResourceFromRemoteURL:inRemoteURL])
		[self enqueueURLForDownload:inRemoteURL];
	
}


- (void) enqueueURLForDownload:(NSURL *)enqueuedURL {

	if ([self.queuedURLs containsObject:enqueuedURL])
		[self.queuedURLs removeObject:enqueuedURL];
	
	[self.queuedURLs insertObject:enqueuedURL atIndex:0];
	
	NSInteger numberOfAccommodatableConnections = self.maximumNumberOfConnections - [self.downloadingURLs count];
	numberOfAccommodatableConnections = MIN([self.queuedURLs count], numberOfAccommodatableConnections);
	
	if (numberOfAccommodatableConnections > 0)
	if ([self.downloadingURLs count] < self.maximumNumberOfConnections) {
	
		NSArray *takenURLs = [self.queuedURLs objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, numberOfAccommodatableConnections)]];
		
		[self.queuedURLs removeObjectsInArray:takenURLs];
		
		for (NSURL *anURL in takenURLs)
			[self createFileHandlerAssociatedWithNewURLRequestForRemoteURL:anURL];
			
	}

}





- (void) createFileHandlerAssociatedWithNewURLRequestForRemoteURL:(NSURL *)inRemoteURL {



	for (id existingObject in [[self.cachedURLsToFilePaths allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isEqual:[inRemoteURL absoluteString]];
	}]]) {
		[self.cachedURLsToFilePaths removeObjectForKey:[inRemoteURL absoluteString]];
	}
	
	[self.cache removeObjectForKey:[inRemoteURL absoluteString]];
	
	
	[self.downloadingURLs addObject:inRemoteURL];
	
	dispatch_async(self.fileHandleDispatchQueue, ^ {
	
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		NSError *error;
		NSFileHandle *fileHandle;
		NSString *filePath = [self pathForCachedContentsOfRemoteURL:inRemoteURL];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		if (![[NSData data] writeToFile:filePath options:NSDataWritingFileProtectionNone error:&error])
			NSLog(@"Error creating file at path %@: %@", filePath, error);
		
		if (!(fileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error])) {
			NSLog(@"error getting file handle to write cache file for URL %@ to local path %@: %@", inRemoteURL, fileURL, error);
			return;		
		}
		
		objc_setAssociatedObject(fileHandle, &kIRRemoteResourcesManagerFilePath, filePath, OBJC_ASSOCIATION_COPY_NONATOMIC);
		
		[fileHandle truncateFileAtOffset:0];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			NSURLConnection *connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:inRemoteURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10] delegate:self];

			CFDictionaryAddValue(connectionsToRemoteURLs, connection, inRemoteURL);
			CFDictionaryAddValue(connectionsToFileHandles, connection, fileHandle);
			
			[self.delegate remoteResourcesManager:self didBeginDownloadingResourceAtURL:inRemoteURL];
							
			[connection start];
	
		});
		
		[pool drain];
	
	});
	
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

	NSFileHandle *fileHandle = (NSFileHandle *)(CFDictionaryGetValue(connectionsToFileHandles, connection));

	dispatch_async(self.fileHandleDispatchQueue, ^ {
	
		@try {
		
			[fileHandle writeData:data];	
		
		}  @catch (NSException *e) {
			
			NSLog(@"File handle %@",fileHandle);
			NSLog(@"Warning: Exception %@", e);
			
		}

	});

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

	NSURL *remoteURL = [[(NSURL *)(CFDictionaryGetValue(connectionsToRemoteURLs, connection)) retain] autorelease];
	
	[self.downloadingURLs removeObject:remoteURL];

	NSFileHandle *fileHandle = (NSFileHandle *)(CFDictionaryGetValue(connectionsToFileHandles, connection));
	NSString *filePath = objc_getAssociatedObject(fileHandle, &kIRRemoteResourcesManagerFilePath);
	[self.cachedURLsToFilePaths setObject:filePath forKey:[remoteURL absoluteString]];
	
	dispatch_async(self.fileHandleDispatchQueue, ^ {
	
		[fileHandle closeFile];
		
		NSPurgeableData *purgableCachedData = [[[NSPurgeableData alloc] initWithContentsOfMappedFile:filePath] autorelease];
		
		if (purgableCachedData)
			[self.cache setObject:purgableCachedData forKey:[remoteURL absoluteString] cost:[purgableCachedData length]];	
		else
			NSLog(@"Warning: %s did not get any purgable cached data", __PRETTY_FUNCTION__);

		[self notifyUpdatedResourceForRemoteURL:remoteURL];
		
		dispatch_async(dispatch_get_main_queue(), ^ {

			CFDictionaryRemoveValue(connectionsToRemoteURLs, connection);
			CFDictionaryRemoveValue(connectionsToFileHandles, connection);
					
		});
		
		[self.delegate remoteResourcesManager:self didFinishDownloadingResourceAtURL:remoteURL];
	
	});
	
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	NSURL *remoteURL = [[(NSURL *)(CFDictionaryGetValue(connectionsToRemoteURLs, connection)) retain] autorelease];
	
	[self.downloadingURLs removeObject:remoteURL];

	NSFileHandle *fileHandle = (NSFileHandle *)(CFDictionaryGetValue(connectionsToFileHandles, connection));
	
	dispatch_async(self.fileHandleDispatchQueue, ^ {
	
		[fileHandle closeFile];
		
		//	FIXME: Remove the file
		
		dispatch_async(dispatch_get_main_queue(), ^ {

			CFDictionaryRemoveValue(connectionsToRemoteURLs, connection);
			CFDictionaryRemoveValue(connectionsToFileHandles, connection);
					
		});
		
		[self.delegate remoteResourcesManager:self didFailDownloadingResourceAtURL:remoteURL];
	
	});

}





- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL {

	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:kIRRemoteResourcesManagerDidRetrieveResourceNotification object:inRemoteURL] postingStyle:NSPostNow coalesceMask:NSNotificationNoCoalescing forModes:nil];

}

- (BOOL) hasStableResourceForRemoteURL:(NSURL *)inRemoteURL {

	if ([self isDownloadingResourceFromRemoteURL:inRemoteURL])
	return NO;
	
	if (![self hasCachedResourceForRemoteURL:inRemoteURL])
	return NO;
	
	return YES;
	
}

- (id) cachedResourceAtRemoteURL:(NSURL *)inRemoteURL {

	return [self.cache objectForKey:[inRemoteURL absoluteString]];

}

- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL skippingUncachedFile:(BOOL)inSkipsIO {

	id cachedObjectOrNil = [self cachedResourceAtRemoteURL:inRemoteURL];
	if (!cachedObjectOrNil || ([cachedObjectOrNil length] == 0)) {
	
		void (^operation)() = ^ {
		
			id cacheKey = [inRemoteURL absoluteString];
			
			[self.cache removeObjectForKey:cacheKey];
		
			if (![self hasStableResourceForRemoteURL:inRemoteURL])
				return;
			
			NSPurgeableData *purgableCachedData = [NSPurgeableData dataWithContentsOfMappedFile:[self pathForCachedContentsOfRemoteURL:[self.cachedURLsToFilePaths objectForKey:[inRemoteURL absoluteString]]]];
		
			if (purgableCachedData)
				[self.cache setObject:purgableCachedData forKey:[inRemoteURL absoluteString] cost:[purgableCachedData length]];	
			else
				NSLog(@"Warning: %s did not get any purgable cached data", __PRETTY_FUNCTION__);
		
		};
		
		if (inSkipsIO) {
		
			return nil;
		
		} else {
		
			operation();
			
			return [self cachedResourceAtRemoteURL:inRemoteURL];
		
		}
	
	}

	return cachedObjectOrNil;

}

- (id) resourceAtRemoteURL:(NSURL *)inRemoteURL {

	return [self resourceAtRemoteURL:inRemoteURL skippingUncachedFile:YES];
	
	id cachedObjectOrNil = [self cachedResourceAtRemoteURL:inRemoteURL];
	
	if (!cachedObjectOrNil) {
	
		dispatch_async(self.fileHandleDispatchQueue, ^ {
		
			if (![self hasStableResourceForRemoteURL:inRemoteURL])
			return;

			id cacheKey = [inRemoteURL absoluteString];
		
			NSPurgeableData *purgableCachedData = [NSPurgeableData dataWithContentsOfMappedFile:[self pathForCachedContentsOfRemoteURL:inRemoteURL]];
		
			if (purgableCachedData)
				[self.cache setObject:purgableCachedData forKey:cacheKey cost:[purgableCachedData length]];	
			else
				NSLog(@"Warning: %s did not get any purgable cached data", __PRETTY_FUNCTION__);
		
		});

	}
	
	return cachedObjectOrNil;

}

- (UIImage *) imageAtRemoteURL:(NSURL *)inRemoteURL {

	NSData *imageData = [self resourceAtRemoteURL:inRemoteURL];
		
	if (!imageData)
	return nil;
	
	UIImage *returnedImage = [UIImage imageWithData:[self resourceAtRemoteURL:inRemoteURL]];
	
	if (!returnedImage) {
	
		[self retrieveResourceAtRemoteURL:inRemoteURL forceReload:YES];
		
		return nil;
	
	}
	
	return returnedImage;

}





- (void) retrieveResource:(NSURL *)resourceURL withCallback:(void(^)(NSData *returnedDataOrNil))aBlock {

	NSURL *downloadingURLOrNil = [self downloadingResourceURLMatchingURL:resourceURL];
	NSURL *notifiedURL = downloadingURLOrNil ? downloadingURLOrNil : resourceURL;
	
	NSData *probableData = [self resourceAtRemoteURL:notifiedURL skippingUncachedFile:NO];

	if (probableData && [probableData length]) {

		if (aBlock)
		aBlock(probableData);

		return;

	}
	
	__block id opaqueReference = nil;
	
	opaqueReference = [[[NSNotificationCenter defaultCenter] addObserverForName:kIRRemoteResourcesManagerDidRetrieveResourceNotification object:notifiedURL queue:nil usingBlock:^(NSNotification *arg1) {
	
		NSData *ensuredData = [self resourceAtRemoteURL:notifiedURL skippingUncachedFile:NO];

		if (!ensuredData) {
		
			NSLog(@"EHEM, there shall be data.");
		
		}

		if (aBlock)
		aBlock(ensuredData);

		[[NSNotificationCenter defaultCenter] removeObserver:opaqueReference];
		
		[opaqueReference autorelease];
	
	}] retain];
	
	if (notifiedURL != downloadingURLOrNil)
	[self retrieveResourceAtRemoteURL:notifiedURL forceReload:YES];

}





@end
