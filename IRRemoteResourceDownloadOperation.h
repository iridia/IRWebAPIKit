//
//  IRRemoteResourceDownloadOperation.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 9/16/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

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
