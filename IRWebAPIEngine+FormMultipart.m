//
//  IRWebAPIEngine+FormMultipart.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine+FormMultipart.h"

#import "IRWebAPIEngine+LocalCaching.h"

NSString * const kIRWebAPIEngineRequestContextFormMultipartFieldsKey = @"kIRWebAPIEngineRequestContextFormMultipartFieldsKey";

@implementation IRWebAPIEngine (FormMultipart)

+ (IRWebAPIRequestContextTransformer) defaultFormMultipartTransformer {

	return [[(^ (NSDictionary *inOriginalContext) {
	
		NSDictionary *formNamesToContents = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
		
		if(!formNamesToContents || ([formNamesToContents count] == 0))
		return inOriginalContext;
		
		NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
		
		NSError *error;
		NSURL *fileHandleURL = [[[self class] newTemporaryFileURL] autorelease];
		
		if (![[NSFileManager defaultManager] createFileAtPath:[fileHandleURL path] contents:[NSData data] attributes:nil]) {
		
			NSLog(@"Error creating file for URL %@.", fileHandleURL);
			return (NSDictionary *)returnedContext;
		
		}
		
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:fileHandleURL error:&error];
		if (!fileHandle) {
		
			NSLog(@"Error grabbing file handle for URL %@: %@", fileHandleURL, error);
			return (NSDictionary *)returnedContext;
		
		}
		
		[fileHandle truncateFileAtOffset:0];
		[fileHandle seekToEndOfFile];
		
		
		NSMutableDictionary *headerFields = [returnedContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields];
		if (!headerFields) {
		
			headerFields = [NSMutableDictionary dictionary];
			[returnedContext setObject:headerFields forKey:kIRWebAPIEngineRequestHTTPHeaderFields];
			
		}
		
		[headerFields setObject:@"8bit" forKey:@"Content-Transfer-Encoding"];
		
		
		NSString *mineBoundary = [NSString stringWithFormat:@"----_=_%@_%@_%@_=_----",
		
			NSStringFromClass([self class]),
			[[NSBundle mainBundle] bundleIdentifier],
			IRWebAPIKitNonce()
			
		];
		
		NSData *boundaryData = [mineBoundary dataUsingEncoding:NSUTF8StringEncoding];
		NSData *newLineData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
		NSData *separatorData = [@"--" dataUsingEncoding:NSUTF8StringEncoding];
		
		[headerFields setObject:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", mineBoundary] forKey:@"Content-Type"];
		
		//	Start writing
		
		for (id incomingFormName in formNamesToContents) {
		
		//	--<BOUNDARY> ↵
			[fileHandle writeData:separatorData];
			[fileHandle writeData:boundaryData];
			[fileHandle writeData:newLineData];
			
			id incomingObject = [formNamesToContents objectForKey:incomingFormName];
			if ([incomingObject isKindOfClass:[NSString class]]) {
			
			//	Append contents of string
			
				[fileHandle writeData:[[NSString stringWithFormat:
				
					@"Content-Disposition: form-data; name=\"%@\"",
					incomingFormName
				
				] dataUsingEncoding:NSUTF8StringEncoding]];
				
				[fileHandle writeData:newLineData];
				[fileHandle writeData:newLineData];
			
				[fileHandle writeData:[(NSString *)incomingObject dataUsingEncoding:NSUTF8StringEncoding]];
			
			} else if ([incomingObject isKindOfClass:[NSURL class]]) {
			
			//	Append contents of file
			
				[fileHandle writeData:[[NSString stringWithFormat:
				
					@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"",
					incomingFormName,
					[[(NSURL *)incomingObject path] lastPathComponent]
				
				] dataUsingEncoding:NSUTF8StringEncoding]];
				
				[fileHandle writeData:newLineData];
				
				
				NSString *mimeType = IRWebAPIKitMIMETypeOfExtension([[[(NSURL *)incomingObject path] lastPathComponent] pathExtension]);
				
				[fileHandle writeData:[[NSString stringWithFormat:
				
					@"Content-Type: %@", (mimeType ? mimeType : @"application/octet-stream")
				
				] dataUsingEncoding:NSUTF8StringEncoding]];				

				[fileHandle writeData:newLineData];
				[fileHandle writeData:newLineData];
			
				[fileHandle writeData:[NSData dataWithContentsOfMappedFile:[(NSURL *)incomingObject path]]];
			
			} else if ([incomingObject isKindOfClass:[NSData class]]) {
			
				[fileHandle writeData:(NSData *)incomingObject];
			
			} else {
			
				NSAssert(NO, @"%s Can’t understand incoming object %@", __PRETTY_FUNCTION__, incomingObject);
			
			}

			[fileHandle writeData:newLineData];
		
		}
		
	//	--<BOUNDARY>-- ↵
		[fileHandle writeData:separatorData];
		[fileHandle writeData:boundaryData];
		[fileHandle writeData:separatorData];
		[fileHandle writeData:newLineData];
		
		[fileHandle closeFile];
		
		[returnedContext setObject:[NSData dataWithContentsOfMappedFile:[fileHandleURL path]] forKey:kIRWebAPIEngineRequestHTTPBody];
		
		
		NSMutableArray *temporaryFileURLs = [returnedContext objectForKey:kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey];
		if (!temporaryFileURLs) {
		
			temporaryFileURLs = [NSMutableArray array];
			[returnedContext setObject:temporaryFileURLs forKey:kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey];
			
		}
		
		[temporaryFileURLs addObject:fileHandleURL];
		
		[returnedContext setObject:temporaryFileURLs forKey:kIRWebAPIEngineRequestContextLocalCachingTemporaryFileURLsKey];
		[returnedContext removeObjectForKey:kIRWebAPIEngineRequestContextFormMultipartFieldsKey];
		[returnedContext setObject:@"POST" forKey:kIRWebAPIEngineRequestHTTPMethod];
		
		return (NSDictionary *)returnedContext;
	
	}) copy] autorelease];

}

@end
