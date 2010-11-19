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
@property (nonatomic, assign, readwrite) CFMutableDictionaryRef dataStore;

@end


@implementation IRWebAPIEngine

@synthesize parser, context, successHandlers, failureHandlers, dataStore;
@synthesize globalRequestTransformers, requestTransformers, globalResponseTransformers, responseTransformers;





- (id) initWithContext:(IRWebAPIContext *)inContext {

	self = [super init]; if (!self) return nil;
	
	context = [inContext retain];
	
	successHandlers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRetain(successHandlers);

	failureHandlers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(failureHandlers);

	dataStore = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(dataStore);
	
	globalRequestTransformers = [[NSMutableArray array] retain];
	requestTransformers = [[NSMutableDictionary dictionary] retain];

	globalResponseTransformers = [[NSMutableArray array] retain];
	responseTransformers = [[NSMutableDictionary dictionary] retain];
	
	return self;

}

- (id) init {

	return [self initWithContext:nil];

}

- (void) dealloc {

	[context release];
	
	CFRelease(successHandlers);
	CFRelease(failureHandlers);
	CFRelease(dataStore);

	[globalRequestTransformers release];
	[requestTransformers release];

	[globalResponseTransformers release];
	[responseTransformers release];

	[super dealloc];

}





- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler {

	if (!self.parser) {

		NSLog(@"Warning: IRWebAPIEngine is designed to work with a parser.  Without one, the response will be sent as a default dictionary.");
		self.parser = IRWebAPIResponseDefaultParserMake();
	
	}

	dispatch_async(dispatch_get_main_queue(), ^{
	
		NSMutableDictionary *arguments = [inArgumentsOrNil mutableCopy];
		if (!arguments) arguments = [NSMutableDictionary dictionary];
		
	
	//	Transform
	//	TODO: Support custom parser block for method
		
		NSDictionary *transformedContext = [NSDictionary dictionaryWithObjectsAndKeys:
		
			[self.context baseURLForMethodNamed:inMethodName], kIRWebAPIEngineRequestHTTPBaseURL,
			[NSMutableDictionary dictionary], kIRWebAPIEngineRequestHTTPHeaderFields,
			arguments, kIRWebAPIEngineRequestHTTPQueryParameters,
			[NSNull null], kIRWebAPIEngineRequestHTTPBody,
			@"GET", kIRWebAPIEngineRequestHTTPMethod,
		
		nil];
		
		NSLog(@"pre");
		
		for (IRWebAPITransformer transformerBlock in self.globalRequestTransformers)
		transformedContext = [transformerBlock(transformedContext) mutableCopy];
		
		if ([self.requestTransformers objectForKey:inMethodName])
		for (IRWebAPITransformer transformerBlock in [self.requestTransformers objectForKey:inMethodName])
		transformedContext = [transformerBlock(transformedContext) mutableCopy];
		
	
	//	Create Request
		
		NSURL *requestBaseURL = (NSURL *)[transformedContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
		
			NSDictionary *queryParameters = [transformedContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			NSMutableArray *queryParametersArray = [NSMutableArray array];
			
		if ([queryParameters count] != 0) {
			
			for (NSString *queryParameterKey in queryParameters)
			[queryParametersArray addObject:[NSString stringWithFormat:
			
				@"%@=%@",
				
				[queryParameterKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
				[(NSString *)[queryParameters objectForKey:queryParameterKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
				
			]];
			
			requestBaseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",
			
				[requestBaseURL absoluteString],
				[queryParametersArray componentsJoinedByString:@"&"]				
			
			]];
			
		}
		
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestBaseURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
		
			NSDictionary *headerFields;
			if (headerFields = [transformedContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields])
			for (NSString *headerFieldKey in headerFields)
			[request setValue:[headerFields objectForKey:headerFieldKey] forHTTPHeaderField:headerFieldKey];
			
			NSData *httpBody = [transformedContext objectForKey:kIRWebAPIEngineRequestHTTPBody];
			if (![httpBody isEqual:[NSNull null]])
			[request setHTTPBody:httpBody];
			
			[request setHTTPMethod:[transformedContext objectForKey:kIRWebAPIEngineRequestHTTPMethod]];
		
		
		NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		CFDictionaryAddValue(successHandlers, connection, [[^ (NSData *inResponse) {
		
			BOOL shouldRetry = NO;
			BOOL notifyDelegate = NO;
			
			NSDictionary *parsedResponse = self.parser([[inResponse retain] autorelease]);
			
			for (IRWebAPITransformer transformerBlock in self.globalResponseTransformers)
			parsedResponse = transformerBlock(parsedResponse);
			
			if (inSuccessHandler)
			inSuccessHandler(self, parsedResponse, &notifyDelegate, &shouldRetry);
			
			if (shouldRetry)
			NSLog(@"Should Retry");
		//	FIXME: WHEN?
				
			if (notifyDelegate)
			NSLog(@"Should Notify Delegate");
		//	FIXME: HOW?

		} copy] retain]);
		
		CFDictionaryAddValue(failureHandlers, connection, [[^ {
		
			BOOL shouldRetry = NO;
			BOOL notifyDelegate = NO;
			
			if (inFailureHandler)
			inFailureHandler(self, [NSDictionary dictionaryWithObject:@"TEST FAIL" forKey:@"FOO"], &notifyDelegate, &shouldRetry);
			
			if (shouldRetry)
			NSLog(@"Should Retry");
			
			if (notifyDelegate)
			NSLog(@"Should Notify Delegate");
		
		} copy] retain]);
		
		CFDictionaryAddValue(dataStore, connection, [NSMutableData data]);
		
		[connection start];
	
	});

}





- (void) connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)inData {

	dispatch_async(dispatch_get_global_queue(0, 0), ^{

		id connectionDataStoreOrNil = (NSData *)CFDictionaryGetValue(self.dataStore, inConnection);
		if (!connectionDataStoreOrNil) return;

		NSMutableData *connectionDataStore = connectionDataStoreOrNil;
		[connectionDataStore appendData:inData];
	
	});

}





- (void) connectionDidFinishLoading:(NSURLConnection *)inConnection {

	dispatch_async(dispatch_get_global_queue(0, 0), ^{

		id successHandlerOrNil = (void (^)(NSData *))CFDictionaryGetValue(self.successHandlers, inConnection);
		if (!successHandlerOrNil) return;

		id connectionDataStoreOrNil = (NSData *)CFDictionaryGetValue(self.dataStore, inConnection);
		if (!connectionDataStoreOrNil) return;
		
		void (^successBlock)() = successHandlerOrNil;
		NSMutableData *connectionDataStore = connectionDataStoreOrNil;
		
		successBlock(connectionDataStore);
		dispatch_async(dispatch_get_main_queue(), ^{
	
			CFDictionaryRemoveValue(self.successHandlers, inConnection);
			CFDictionaryRemoveValue(self.failureHandlers, inConnection);
			CFDictionaryRemoveValue(self.dataStore, inConnection);
				
		});
	
	});
	
}





- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
	
		id failureHandlerOrNil = (void (^)(void))CFDictionaryGetValue(self.failureHandlers, connection);
		if (!failureHandlerOrNil) return;
		
		void (^failureBlock)(void) = failureHandlerOrNil;
		
		failureBlock();
		dispatch_async(dispatch_get_main_queue(), ^{
		
			CFDictionaryRemoveValue(self.successHandlers, connection);
			CFDictionaryRemoveValue(self.failureHandlers, connection);
			CFDictionaryRemoveValue(self.dataStore, connection);
		
		});
	
	});

}

@end
