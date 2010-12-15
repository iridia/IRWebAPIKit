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

- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler;

@end


@implementation IRWebAPIEngine

@synthesize parser, context, successHandlers, failureHandlers, dataStore;
@synthesize globalRequestPreTransformers, globalRequestPostTransformers, requestTransformers, globalResponsePreTransformers, globalResponsePostTransformers, responseTransformers;





- (id) initWithContext:(IRWebAPIContext *)inContext {

	self = [super init]; if (!self) return nil;
	
	context = [inContext retain];
	
	successHandlers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRetain(successHandlers);

	failureHandlers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(failureHandlers);

	dataStore = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);	
	CFRetain(dataStore);
	
	globalRequestPreTransformers = [[NSMutableArray array] retain];
	requestTransformers = [[NSMutableDictionary dictionary] retain];
	globalRequestPostTransformers = [[NSMutableArray array] retain];

	globalResponsePreTransformers = [[NSMutableArray array] retain];
	responseTransformers = [[NSMutableDictionary dictionary] retain];
	globalResponsePostTransformers = [[NSMutableArray array] retain];
	
	sharedDispatchQueue = dispatch_queue_create("com.iridia.WebAPIEngine.queue.main", NULL);
	
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

	[globalRequestPreTransformers release];
	[requestTransformers release];
	[globalRequestPostTransformers release];

	[globalResponsePreTransformers release];
	[responseTransformers release];
	[globalResponsePostTransformers release];
	
	dispatch_release(sharedDispatchQueue);

	[super dealloc];

}





- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler {

	[self fireAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:nil onSuccess:inSuccessHandler onFailure:inFailureHandler];

}





- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler {

	if (!self.parser) {

		NSLog(@"Warning: IRWebAPIEngine is designed to work with a parser.  Without one, the response will be sent as a default dictionary.");
		self.parser = IRWebAPIResponseDefaultParserMake();
	
	}
	
	dispatch_async(
	
		dispatch_get_global_queue(0, 0), 
	
		[self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil onSuccess:inSuccessHandler onFailure:inFailureHandler]
		
	);
	
}





- (void) enqueueAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler {

	if (!self.parser) {

		NSLog(@"Warning: IRWebAPIEngine is designed to work with a parser.  Without one, the response will be sent as a default dictionary.");
		self.parser = IRWebAPIResponseDefaultParserMake();
	
	}
	
	dispatch_async(
	
		sharedDispatchQueue, 
	
		[self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil onSuccess:inSuccessHandler onFailure:inFailureHandler]
		
	);
	
}




	
- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler {

	void (^returnedBlock) (void) = ^ {
	
		NSMutableDictionary *arguments;
		
		if (inArgumentsOrNil) {
		
			arguments = [[inArgumentsOrNil mutableCopy] autorelease];
		
		} else {
		
			arguments = [NSMutableDictionary dictionary];
		
		}
		
	
	//	Transform Context.
		
		NSMutableDictionary *transformedContext = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		
			[self.context baseURLForMethodNamed:inMethodName], kIRWebAPIEngineRequestHTTPBaseURL,
			[NSMutableDictionary dictionary], kIRWebAPIEngineRequestHTTPHeaderFields,
			arguments, kIRWebAPIEngineRequestHTTPQueryParameters,
			[NSNull null], kIRWebAPIEngineRequestHTTPBody,
			@"GET", kIRWebAPIEngineRequestHTTPMethod,

			self.parser, kIRWebAPIEngineParser,
		
		nil];
		
		for (id optionValueKey in inOptionsOrNil)
		[transformedContext setValue:[inOptionsOrNil valueForKey:optionValueKey] forKey:optionValueKey];
		
		for (IRWebAPITransformer transformerBlock in self.globalRequestPreTransformers)
		transformedContext = [[transformerBlock(transformedContext) mutableCopy] autorelease];
		
		for (IRWebAPITransformer transformerBlock in [self requestTransformersForMethodNamed:inMethodName])
		transformedContext = [[transformerBlock(transformedContext) mutableCopy] autorelease];

		for (IRWebAPITransformer transformerBlock in self.globalRequestPostTransformers)
		transformedContext = [[transformerBlock(transformedContext) mutableCopy] autorelease];
		
	
	//	Create Request
		
		NSURL *requestBaseURL = (NSURL *)[transformedContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
		
			NSDictionary *queryParameters = [transformedContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters];
			NSMutableArray *queryParametersArray = [NSMutableArray array];
			
		if ([queryParameters count] != 0) {
			
			for (NSString *queryParameterKey in queryParameters)
			[queryParametersArray addObject:[NSString stringWithFormat:
			
				@"%@=%@",
				
				[queryParameterKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
				[IRWebAPIKitStringValue([queryParameters objectForKey:queryParameterKey]) stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
				
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
		
		
		dispatch_async(dispatch_get_main_queue(), ^{
		
			NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
			
			CFDictionaryAddValue(successHandlers, connection, [[^ (NSData *inResponse) {
					
				BOOL shouldRetry = NO;
				BOOL notifyDelegate = NO;
				
				IRWebAPIResponseParser parserBlock = [transformedContext objectForKey:kIRWebAPIEngineParser];
				NSDictionary *parsedResponse = parserBlock([[inResponse retain] autorelease]);
				
				for (IRWebAPITransformer transformerBlock in self.globalResponsePreTransformers)
				parsedResponse = transformerBlock(parsedResponse);
				
				for (IRWebAPITransformer transformerBlock in [self responseTransformersForMethodNamed:inMethodName])
				parsedResponse = transformerBlock(parsedResponse);
				
				for (IRWebAPITransformer transformerBlock in self.globalResponsePostTransformers)
				parsedResponse = transformerBlock(parsedResponse);
				
				if (inSuccessHandler)
				inSuccessHandler(self, parsedResponse, &notifyDelegate, &shouldRetry);
				
				if (shouldRetry) {

					[self enqueueAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil onSuccess:inSuccessHandler onFailure:inFailureHandler];
					
				}

				if (notifyDelegate)
				NSLog(@"Should Notify Delegate");
			//	FIXME: HOW?

			} copy] autorelease]);
			
			CFDictionaryAddValue(failureHandlers, connection, [[^ {
			
				BOOL shouldRetry = NO;
				BOOL notifyDelegate = NO;
				
				if (inFailureHandler)
				inFailureHandler(self, [NSDictionary dictionaryWithObject:@"TEST FAIL" forKey:@"FOO"], &notifyDelegate, &shouldRetry);
				
				if (shouldRetry) {
				
					[self enqueueAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil onSuccess:inSuccessHandler onFailure:inFailureHandler];
					
				}
				
				if (notifyDelegate)
				NSLog(@"Should Notify Delegate");
			
			} copy] autorelease]);
			
			CFDictionaryAddValue(dataStore, connection, [NSMutableData data]);
			
			[connection start];
		
		});
	
	};
	
	return [[returnedBlock copy] autorelease];

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










- (NSMutableArray *) requestTransformersForMethodNamed:(NSString *)inMethodName {

	NSMutableArray *returnedArray = [self.requestTransformers objectForKey:inMethodName];
	
	if (!returnedArray) {
	
		returnedArray = [NSMutableArray array];
		[self.requestTransformers setObject:returnedArray forKey:inMethodName];
		
	}
	
	return returnedArray;

}

- (NSMutableArray *) responseTransformersForMethodNamed:(NSString *)inMethodName {

	NSMutableArray *returnedArray = [self.responseTransformers objectForKey:inMethodName];
	
	if (!returnedArray) {
	
		returnedArray = [NSMutableArray array];
		[self.responseTransformers setObject:returnedArray forKey:inMethodName];
		
	}
	
	return returnedArray;

}





@end
