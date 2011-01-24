//
//  IRWebAPITwitPicInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitPicInterface.h"


@implementation IRWebAPITwitPicInterface

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

- (void) uploadImageAtURL:(NSURL *)inImageURL onSuccess:(IRWebAPIInterfaceCallback)inSuccessCallback onFailure:(IRWebAPIInterfaceCallback)inFailureCallback {

	NSAssert(self.apiKey, @"%@ needs an API key.", self);
	NSAssert(self.authenticatingInterface, @"%@ needs an authenticating interface so oAuth Echo works.", self);
	
	NSAssert(NO, @"Implement!");
	
	[self.engine fireAPIRequestNamed:@"test.php" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		self.apiKey, @"key",
	
	nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSDictionary dictionaryWithObjectsAndKeys:
		
			inImageURL, @"image",
		
		nil], kIRWebAPIEngineRequestContextFormMultipartFieldsKey,
	
	nil] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSLog(@"Success: %@", inResponseOrNil);
	
	} failureHandler:nil];

}

@end
