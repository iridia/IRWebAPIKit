//
//  IRRemoteResourceDownloadOperation.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 9/16/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRRemoteResourceDownloadOperation.h"

@interface IRRemoteResourceDownloadOperation ()

@property (nonatomic, readwrite, retain) NSString *path;
@property (nonatomic, readwrite, retain) NSURL *url;
@property (nonatomic, readwrite, assign) long long processedBytes;
@property (nonatomic, readwrite, assign) long long totalBytes;
@property (nonatomic, readwrite, assign) long long preferredByteOffset;
@property (nonatomic, readwrite, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, readwrite, assign, getter=isFinished) BOOL finished;
@property (nonatomic, readwrite, assign, getter=isCancelled) BOOL cancelled;
@property (nonatomic, readwrite, retain) NSFileHandle *fileHandle;
@property (nonatomic, readwrite, retain) NSURLConnection *connection;
@property (nonatomic, readwrite, assign) dispatch_queue_t actualDispatchQueue;
@property (nonatomic, readwrite, retain) NSMutableArray *appendedCompletionBlocks;

- (void) onMainQueue:(void(^)(void))aBlock;
- (void) onOriginalQueue:(void(^)(void))aBlock;

@property (nonatomic, readwrite, copy) void(^onMain)(void);

@end


@implementation IRRemoteResourceDownloadOperation

@synthesize path, url, processedBytes, totalBytes, preferredByteOffset, executing, finished, cancelled;
@synthesize fileHandle, connection;
@synthesize actualDispatchQueue;
@synthesize onMain;
@synthesize appendedCompletionBlocks;

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
	[appendedCompletionBlocks release];
	
	[super dealloc];

}

- (void) onMainQueue:(void(^)(void))aBlock {
	
	if (!self.actualDispatchQueue)
		self.actualDispatchQueue = dispatch_get_current_queue();
	
	if ([NSThread isMainThread]) {
		aBlock();
		return;
	}
	
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

- (void) cancel {

	[self onMainQueue: ^ {		
		[self.connection cancel];
	}];
	
	[self onOriginalQueue: ^ {
		[self.fileHandle closeFile];
	}];

	self.cancelled = YES;
	self.executing = NO;
	self.finished = YES;

}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

	NSParameterAssert(![self isCancelled]);
	
	[self onOriginalQueue: ^ {

		self.totalBytes = response.expectedContentLength;
		
	}];

}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {

	NSParameterAssert(![self isCancelled]);

	[self onOriginalQueue: ^ {
	
		self.processedBytes += [data length];
		[self.fileHandle writeData:data];
	
	}];

}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {

	NSParameterAssert(![self isCancelled]);
	
	[self onOriginalQueue: ^ {
	
		[self.fileHandle closeFile];
		
		self.executing = NO;
		self.finished = YES;
	
	}];

}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	NSParameterAssert(![self isCancelled]);

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

- (NSString *) description {

	return [NSString stringWithFormat:
	
		@"<%@: 0x%x> "
		
		//	@"Offset: %lu, "
		
		@"URL: %@, "
		@"Path: %@, "
		@"Completion Blocks: %@, "
		
		@"Executing: %x, "
		@"Cancelled: %x, "
		@"Finished: %x ",
		
		NSStringFromClass([self class]), (unsigned int)self, 

		//	self.preferredByteOffset,
		
		self.url, 
		self.path, 
		self.appendedCompletionBlocks,
		
		self.executing,
		self.cancelled,
		self.finished
		
	];

}

- (NSMutableArray *) appendedCompletionBlocks {

	if (appendedCompletionBlocks)
		return appendedCompletionBlocks;
	
	appendedCompletionBlocks = [[NSMutableArray array] retain];
	return appendedCompletionBlocks;

}

- (void) appendCompletionBlock:(void (^)(void))aBlock {

	[self.appendedCompletionBlocks addObject:[[aBlock copy] autorelease]];

}

- (void) invokeCompletionBlocks {

	for (void(^aBlock)(void) in [[self.appendedCompletionBlocks copy] autorelease])
		aBlock();
	
	self.appendedCompletionBlocks = [NSMutableArray array];

}

- (IRRemoteResourceDownloadOperation *) continuationOperationCancellingCurrentOperation:(BOOL)cancelsCurrentOperation {

	__block IRRemoteResourceDownloadOperation *continuationOperation = [[[[self class] alloc] init] autorelease];
	continuationOperation.path = self.path;
	continuationOperation.url = self.url;
	continuationOperation.preferredByteOffset = self.processedBytes;
	continuationOperation.totalBytes = self.totalBytes;
	continuationOperation.appendedCompletionBlocks = self.appendedCompletionBlocks;

	if (cancelsCurrentOperation) {
		[self.connection cancel];
		[self cancel];
	}
	
	return continuationOperation;

}

@end
