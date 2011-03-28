//
//  MLRemoteResourcesManager.m
//  Milk
//
//  Created by Evadne Wu on 12/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRRemoteResourcesManager.h"


@interface IRRemoteResourcesManager ()

@property (nonatomic, readonly, assign) dispatch_queue_t fileHandleDispatchQueue;

@property (readwrite, retain) NSMutableSet *cachedURLs;
@property (readwrite, retain) NSMutableSet *downloadingURLs;

@property (nonatomic, readwrite, retain) NSString *cacheDirectoryPath;

@property (nonatomic, readwrite, assign) CFMutableDictionaryRef connectionsToRemoteURLs;
@property (nonatomic, readwrite, assign) CFMutableDictionaryRef connectionsToFileHandles;

- (void) initializeCacheDirectoryAndRefreshCachedURLs;

- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL;
- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL;

- (void) createFileHandlerAssociatedWithNewURLRequestForRemoteURL:(NSURL *)inRemoteURL;

- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL;

@property (nonatomic, readwrite, retain) NSCache *cache;

@end





@implementation IRRemoteResourcesManager

@synthesize fileHandleDispatchQueue, cachedURLs, downloadingURLs, cacheDirectoryPath, connectionsToRemoteURLs, connectionsToFileHandles, cache;

+ (IRRemoteResourcesManager *) sharedManager {

	static IRRemoteResourcesManager* sharedManagerInstance = nil;
	
	if (!sharedManagerInstance) {
	
		sharedManagerInstance = [[self alloc] init];
		
	}
	
	return sharedManagerInstance;

}

- (id) init {

	self = [super init]; if (!self) return nil;
	
	fileHandleDispatchQueue = dispatch_queue_create("com.iridia.milk.remoteResourcesManager", NULL);
	
	self.cachedURLs = [NSMutableSet set];
	self.downloadingURLs = [NSMutableSet set];
	
	connectionsToRemoteURLs = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(connectionsToRemoteURLs);
	
	connectionsToFileHandles = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(connectionsToFileHandles);
	
	NSString *applicationCacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *preferredCacheDirectoryPath = [applicationCacheDirectory stringByAppendingPathComponent:@"MLRemoteResourcesManager"];
	self.cacheDirectoryPath = preferredCacheDirectoryPath;
	
//		for (id anURL in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[[[NSURL alloc] initFileURLWithPath:self.cacheDirectoryPath] autorelease] includingPropertiesForKeys:nil options:0 error:nil])
//		[[NSFileManager defaultManager] removeItemAtURL:anURL error:nil];
	
	self.cache = [[[NSCache alloc] init] autorelease];
	self.cache.delegate = self;
	[self.cache setTotalCostLimit:1024 * 1024 * 5];	//	1024 Bs * 1024 KBs * 5
	
	[self initializeCacheDirectoryAndRefreshCachedURLs];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidReceiveMemoryWarningNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	return self;

}

- (void) handleDidReceiveMemoryWarningNotification:(NSNotification *)aNotification {

	[self.cache removeAllObjects];

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	dispatch_release(fileHandleDispatchQueue);

	self.cachedURLs = nil;
	self.downloadingURLs = nil;
	
	CFRelease(connectionsToRemoteURLs);
	CFRelease(connectionsToFileHandles);
	
	self.cacheDirectoryPath = nil;
	self.cache = nil;
		
	[super dealloc];

}





- (NSString *) pathForCachedContentsOfRemoteURL:(NSURL *)inRemoteURL {

	return [[self cacheDirectoryPath] stringByAppendingPathComponent:IRWebAPIKitRFC3986EncodedStringMake([inRemoteURL absoluteString])];

}

- (NSURL *) urlForCachedContentWithName:(NSString *)inName {

	return [NSURL URLWithString:IRWebAPIKitRFC3986DecodedStringMake(inName)];

}

- (void) clearCacheDirectory {

	NSError *error;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cachePath = [self cacheDirectoryPath];

	if (![fileManager removeItemAtPath:cachePath error:&error]) {
	
		NSLog(@"Error occurred while removing the cache directory; %@", error);
		return;
	
	}

}

- (void) initializeCacheDirectoryAndRefreshCachedURLs {
	
	NSError *error;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *cachePath = [self cacheDirectoryPath];

	if (![fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error]) {
	
		NSLog(@"Erorr occurred while creating or assuring cache directory: %@", error);
		return;
	
	};
	
	NSArray *cachedURLRepresentations = nil;
	
	if (!(cachedURLRepresentations = [fileManager contentsOfDirectoryAtPath:cachePath error:&error])) {
	
		NSLog(@"Error retrieving list of cached files: %@", error);
		return;
	
	}
	
	[[self cachedURLs] removeAllObjects];
	
	for (NSString *urlRepresentation in cachedURLRepresentations)
	[[self cachedURLs] addObject:[NSURL URLWithString:IRWebAPIKitRFC3986DecodedStringMake(urlRepresentation)]];
		
}





- (BOOL) hasCachedResourceForRemoteURL:(NSURL *)inRemoteURL {

	NSSet *copiedCachedURLs = [[self.cachedURLs copy] autorelease];

	return ([[copiedCachedURLs objectsPassingTest: ^ (id obj, BOOL *stop) {
	
		BOOL equals = [[obj absoluteURL] isEqual:[inRemoteURL absoluteURL]];
		
		*stop = equals;	
		return equals;
	
	}] count] > 0);

}

- (BOOL) isDownloadingResourceFromRemoteURL:(NSURL *)inRemoteURL {

	NSSet *copiedDownloadingURLs = [[self.downloadingURLs copy] autorelease];

	return ([[copiedDownloadingURLs objectsPassingTest: ^ (id obj, BOOL *stop) {
	
		BOOL equals = [[obj absoluteURL] isEqual:[inRemoteURL absoluteURL]];
		
		*stop = equals;	
		return equals;
	
	}] count] > 0);

}

- (NSURL *) downloadingResourceURLMatchingURL:(NSURL *)inRemoteURL {

	NSSet *copiedDownloadingURLs = [[[self.downloadingURLs copy] autorelease] objectsPassingTest:^(id obj, BOOL *stop) {
	
		return [[obj absoluteURL] isEqual:inRemoteURL];
	
	}];
	
	if ([copiedDownloadingURLs count] > 0)
	return [copiedDownloadingURLs anyObject];
	
	return nil;

}





- (void) retrieveResourceAtRemoteURL:(NSURL *)inRemoteURL forceReload:(BOOL)inForceReload {

	if (!inRemoteURL) return;
	
	if (!inForceReload)
	if ([self.cache objectForKey:[inRemoteURL absoluteString]] || [self hasCachedResourceForRemoteURL:inRemoteURL]) {
	
		[self notifyUpdatedResourceForRemoteURL:inRemoteURL];
		return;
	
	}
	
	if ([self isDownloadingResourceFromRemoteURL:inRemoteURL])
	return;

	[self createFileHandlerAssociatedWithNewURLRequestForRemoteURL:inRemoteURL];
	
}





- (void) createFileHandlerAssociatedWithNewURLRequestForRemoteURL:(NSURL *)inRemoteURL {

	for (id existingObject in [self.cachedURLs objectsPassingTest: ^ (id obj, BOOL *stop) {
	
		return [obj isEqual:inRemoteURL];
	
	}]) [self.cachedURLs removeObject:existingObject];
	
	[self.cache removeObjectForKey:[inRemoteURL absoluteString]];
	
	
	[self.downloadingURLs addObject:inRemoteURL];
	
	dispatch_async(self.fileHandleDispatchQueue, ^ {
	
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

		NSError *error;
		NSFileHandle *fileHandle;
		NSString *filePath = [self pathForCachedContentsOfRemoteURL:inRemoteURL];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		if (![[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil]) {
		
			NSLog(@"Error creating file at path %@", filePath);
		
		}
		
		if (!(fileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error])) {
		
			NSLog(@"error getting file handle to write cache file for URL %@ to local path %@: %@", inRemoteURL, fileURL, error);
			return;
		
		}
		
		[fileHandle truncateFileAtOffset:0];
		
		dispatch_async(dispatch_get_main_queue(), ^ {
		
			NSURLConnection *connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:inRemoteURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10] delegate:self];

			CFDictionaryAddValue(connectionsToRemoteURLs, connection, inRemoteURL);
			CFDictionaryAddValue(connectionsToFileHandles, connection, fileHandle);
							
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
	[self.cachedURLs addObject:remoteURL];

	NSFileHandle *fileHandle = (NSFileHandle *)(CFDictionaryGetValue(connectionsToFileHandles, connection));
	
	dispatch_async(self.fileHandleDispatchQueue, ^ {
	
		[fileHandle closeFile];
		
		NSPurgeableData *purgableCachedData = [[[NSPurgeableData alloc] initWithContentsOfMappedFile:[self pathForCachedContentsOfRemoteURL:remoteURL]] autorelease];
	
		[self.cache setObject:purgableCachedData forKey:[self pathForCachedContentsOfRemoteURL:remoteURL] cost:[purgableCachedData length]];	

		[self notifyUpdatedResourceForRemoteURL:remoteURL];
		
		dispatch_async(dispatch_get_main_queue(), ^ {

			CFDictionaryRemoveValue(connectionsToRemoteURLs, connection);
			CFDictionaryRemoveValue(connectionsToFileHandles, connection);
					
		});
	
	});
	
}





- (void) notifyUpdatedResourceForRemoteURL:(NSURL *)inRemoteURL {

        [[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:MLRemoteResourcesManagerDidRetrieveResourceNotification object:inRemoteURL] postingStyle:NSPostNow coalesceMask:NSNotificationNoCoalescing forModes:nil];

//	[[NSNotificationCenter defaultCenter] postNotificationName:MLRemoteResourcesManagerDidRetrieveResourceNotification object:inRemoteURL];

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

			NSPurgeableData *purgableCachedData = [NSPurgeableData dataWithContentsOfMappedFile:[self pathForCachedContentsOfRemoteURL:inRemoteURL]];
		
			[self.cache setObject:purgableCachedData forKey:cacheKey cost:[purgableCachedData length]];	
		
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
		
			[self.cache setObject:purgableCachedData forKey:cacheKey cost:[purgableCachedData length]];	
		
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

	if (probableData) {

		if (aBlock)
		aBlock(probableData);

		return;

	}
	
	__block id opaqueReference = nil;
	
	opaqueReference = [[[NSNotificationCenter defaultCenter] addObserverForName:MLRemoteResourcesManagerDidRetrieveResourceNotification object:notifiedURL queue:nil usingBlock:^(NSNotification *arg1) {
	
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
