//
//  IRWebAPITwitPicInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitPicInterface.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>


@interface IRWebAPITwitPicInterface ()

- (void) uploadCachedImageAtURL:(NSURL *)inCachedImageURL onProgress:(void(^)(float inProgressRatio))inProgressCallback onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback;

//	The reason why we pile other methods here is because we want a method that cleans up after itself, so we use a cached URL.  The cached image is deleted once the method call returns.

@end

@implementation IRWebAPITwitPicInterface

@synthesize apiKey, authenticatingInterface;

- (id) init {

	IRWebAPIContext *twitPicContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"http://api.twitpic.com/"]] autorelease];
	IRWebAPIEngine *twitPicEngine = [[[IRWebAPIEngine alloc] initWithContext:twitPicContext] autorelease];
	
	twitPicEngine.parser = IRWebAPIResponseDefaultJSONParserMake();
		
	self = [self initWithEngine:twitPicEngine authenticator:nil];
	
	[twitPicEngine.globalRequestPreTransformers addObject:[[twitPicEngine class] defaultFormMultipartTransformer]];
	[twitPicEngine.globalResponsePostTransformers addObject:[[twitPicEngine class] defaultCleanUpTemporaryFilesResponseTransformer]];

	if (!self) return nil;

	return self;

}

- (void) uploadImage:(UIImage *)inImage onProgress:(void(^)(float inProgressRatio))inProgressCallback onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSData *imageDataOrNil = UIImagePNGRepresentation(inImage);
	
	if (!imageDataOrNil) {
	
		IRWebAPIKitLog(@"The incoming image can’t be turned to a PNG representation — it might be corrupted or garbled");

		if (inFailureCallback)
		inFailureCallback(nil, NO, NO);
		
		return;
	
	}
	
	NSURL *cachingFileURL = [[[self.engine class] newTemporaryFileURL] autorelease];
	
	[imageDataOrNil writeToURL:cachingFileURL atomically:YES];
	
	[self uploadCachedImageAtURL:cachingFileURL onProgress:inProgressCallback onSuccess:inSuccessCallback onFailure:inFailureCallback];

}

- (void) uploadImageAtURL:(NSURL *)inImageURL onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSURL *cachingFileURL = [[[self.engine class] newTemporaryFileURL] autorelease];

	NSError *error = nil;
	
	if (![[NSFileManager defaultManager] copyItemAtURL:inImageURL toURL:cachingFileURL error:&error]) {
	
		IRWebAPIKitLog(@"Can’t copy item at %@ to %@ — aborting, calling failure handler.", inImageURL, cachingFileURL);
		
		if (inFailureCallback)
		inFailureCallback(nil, NO, NO);
		
		return;
	
	}

	[self uploadCachedImageAtURL:cachingFileURL onProgress:nil onSuccess:inSuccessCallback onFailure:inFailureCallback];

}

- (void) uploadCachedImageAtURL:(NSURL *)inCachedImageURL onProgress:(void(^)(float inProgressRatio))inProgressCallback onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {
	
	
	NSAssert(self.apiKey, @"%@ needs an API key.", self);
	NSAssert(self.authenticatingInterface, @"%@ needs an authenticating interface so oAuth Echo works.", self);
	NSAssert([self.authenticatingInterface.authenticator isKindOfClass:[IRWebAPIXOAuthAuthenticator class]], @"Authenticator needs to be of class %@.", NSStringFromClass([IRWebAPIXOAuthAuthenticator class]));
	NSAssert(self.authenticatingInterface.authenticator.currentCredentials.authenticated, @"%@ needs an authenticating interface with already authenticated credentials to work correctly.", self);


//	Abstraction leaks at this line
	NSURL *xoAuthEchoBaseURL = [NSURL URLWithString:@"1/account/verify_credentials.json" relativeToURL:self.authenticatingInterface.engine.context.baseURL];

	[self.engine fireAPIRequestNamed:@"/2/upload.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		self.apiKey, @"key",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			self.apiKey, @"key",
			inCachedImageURL, @"media",
			@"", @"message",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
		
		[NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			[((IRWebAPIXOAuthAuthenticator *)self.authenticatingInterface.authenticator) oAuthHeaderValueForHTTPMethod:@"GET" baseURL:xoAuthEchoBaseURL arguments:nil], @"X-Verify-Credentials-Authorization",
			
			[xoAuthEchoBaseURL absoluteString], @"X-Auth-Service-Provider",
		
		nil], kIRWebAPIEngineRequestHTTPHeaderFields,
	
	nil] validator: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
	
		NSHTTPURLResponse *response = (NSHTTPURLResponse *)[inResponseContext objectForKey:kIRWebAPIEngineResponseContextURLResponse];
		
		if ([inResponseOrNil objectForKey:@"url"] == nil) {
		
			NSLog(@"Warning: No valid response (%x %@).", [response statusCode], [[response class] localizedStringForStatusCode:[response statusCode]]);
			
			return NO;
		
		}
		
		return YES;
	
	} successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
			
		if (inSuccessCallback)
		inSuccessCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		*outShouldRetry = YES;
	
		if (inFailureCallback)
		inFailureCallback(inResponseOrNil, outNotifyDelegate, outShouldRetry);
	
	}];

}

@end
