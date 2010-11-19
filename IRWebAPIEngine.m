//
//  IRWebAPIEngine.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine.h"





@interface IRWebAPIEngine ()

@property (nonatomic, assign, readwrite) CFMutableDictionaryRef successHandlers;
@property (nonatomic, assign, readwrite) CFMutableDictionaryRef failureHandlers;

@end


@implementation IRWebAPIEngine

@synthesize context, successHandlers, failureHandlers;





- (id) initWithContext:(IRWebAPIContext *)inContext {

	self = [super init]; if (!self) return nil;
	
	context = [inContext retain];
	
	successHandlers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRetain(successHandlers);

	failureHandlers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(failureHandlers);
	
	return self;

}

- (id) init {

	return [self initWithContext:nil];

}

- (void) dealloc {

	[context release];
	
	CFRelease(successHandlers);
	CFRelease(failureHandlers);
	
	[super dealloc];

}





- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler {

	dispatch_async(dispatch_get_main_queue(), ^{
	
		NSURL *requestURL = [self.context baseURLForMethodNamed:inMethodName];				
		NSURLRequest *request = [NSURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
		NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		CFDictionaryAddValue(successHandlers, connection, [[^ {
		
			NSLog(@"Handling connection %@ success", connection);
		
			BOOL shouldRetry = NO;
			BOOL notifyDelegate = NO;

			if (inSuccessHandler)
			inSuccessHandler(self, [NSDictionary dictionaryWithObject:@"TEST RESPONSE" forKey:@"FOO"], &notifyDelegate, &shouldRetry);
			
			if (shouldRetry)
			NSLog(@"Should Retry");
				
			if (notifyDelegate)
			NSLog(@"Should Notify Delegate");

		} copy] retain]);
		
		CFDictionaryAddValue(failureHandlers, connection, [[^ {
		
			NSLog(@"Handling connection %@ failure", connection);
		
			BOOL shouldRetry = NO;
			BOOL notifyDelegate = NO;
			
			if (inFailureHandler)
			inFailureHandler(self, [NSDictionary dictionaryWithObject:@"TEST FAIL" forKey:@"FOO"], &notifyDelegate, &shouldRetry);
			
			if (shouldRetry)
			NSLog(@"Should Retry");
			
			if (notifyDelegate)
			NSLog(@"Should Notify Delegate");
		
		} copy] retain]);
		
		[connection start];
	
	});

}





- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

	id successHandlerOrNil = (void (^)(void))CFDictionaryGetValue(self.successHandlers, connection);
	if (!successHandlerOrNil) return;
	
	void (^successBlock)(void) = successHandlerOrNil;
	successBlock();
	
	CFDictionaryRemoveValue(self.successHandlers, connection);
	
}





- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
	id failureHandlerOrNil = (void (^)(void))CFDictionaryGetValue(self.failureHandlers, connection);
	if (!failureHandlerOrNil) return;
	
	void (^failureBlock)(void) = failureHandlerOrNil;
	failureBlock();
	
	CFDictionaryRemoveValue(self.failureHandlers, connection);

}

@end
