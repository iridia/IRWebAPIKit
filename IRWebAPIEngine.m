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

- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler;

- (NSDictionary *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil;
- (NSDictionary *) requestContextByTransformingContext:(NSDictionary *)inContext forMethodNamed:(NSString *)inMethodName;
- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse forMethodNamed:(NSString *)inMethodName;

- (NSURLRequest *) requestWithContext:(NSDictionary *)inContext;

- (void) ensureResponseParserExistence;

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





- (void) ensureResponseParserExistence {
	
	if (self.parser) return;
	
	NSLog(@"Warning: IRWebAPIEngine is designed to work with a parser.  Without one, the response will be sent as a default dictionary.");
	self.parser = IRWebAPIResponseDefaultParserMake();
	
}





- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(dispatch_get_global_queue(0, 0), [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil validator:inValidator successHandler:inSuccessHandler failureHandler:inFailureHandler]);

}

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(dispatch_get_global_queue(0, 0), [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil validator:nil successHandler:inSuccessHandler failureHandler:inFailureHandler]);
	
}

- (void) enqueueAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(sharedDispatchQueue, [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil validator:nil successHandler:inSuccessHandler failureHandler:inFailureHandler]);
		
}




	
- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	[self ensureResponseParserExistence];

	void (^retryHandler)(void) = ^ {
	
	//	FIXME: Actually, the block doesn’t know if it is enqueued or fired
		[self enqueueAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:inOptionsOrNil successHandler:inSuccessHandler failureHandler:inFailureHandler];
	
	};
	
	void (^notifyDelegateHandler)(void) = ^ {
	
		NSLog(@"Notifying delegate of connection finalization");
	
	};
	
	NSDictionary *finalizedContext = [self requestContextByTransformingContext:[self baseRequestContextWithMethodName:inMethodName arguments:inArgumentsOrNil options:inOptionsOrNil] forMethodNamed:inMethodName];
		
	NSURLRequest *request = [self requestWithContext:finalizedContext];

	void (^returnedBlock) (void) = ^ {
			
		dispatch_async(dispatch_get_main_queue(), ^{
		
			NSURLConnection *connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
						
			CFDictionaryAddValue(successHandlers, connection, [[^ (NSData *inResponse) {
					
				BOOL shouldRetry = NO, notifyDelegate = NO;
				
				IRWebAPIResponseParser parserBlock = [finalizedContext objectForKey:kIRWebAPIEngineParser];

				NSDictionary *parsedResponse = parserBlock(inResponse);		
				if (parsedResponse == nil) {
				
				//	THE RESPONSE IS UNPARSIBLE HERE
				
					NSLog(@"Warning: unparsable response.  Resetting returned response to an empty dictionary.");
					NSLog(@"Context: %@", finalizedContext);
					
					IRWebAPIResponseParser defaultParser = IRWebAPIResponseDefaultParserMake();
					
					NSDictionary *debugOutput = defaultParser(inResponse);
					NSLog(@"Default parser returns %@.", debugOutput ? (id<NSObject>)debugOutput : (id<NSObject>)@"- null -");
					
					parsedResponse = [NSDictionary dictionary];
				
				}
				
				NSDictionary *transformedResponse = [self responseByTransformingResponse:parsedResponse forMethodNamed:inMethodName];
				
				if ((inValidator != nil) && (!inValidator(self, parsedResponse))) {

					if (inFailureHandler)
					inFailureHandler(self, parsedResponse, &notifyDelegate, &shouldRetry);
					
					if (shouldRetry) retryHandler();
					if (notifyDelegate) notifyDelegateHandler();
					
					return;
				
				}
				
				if (inSuccessHandler)
				inSuccessHandler(self, parsedResponse, &notifyDelegate, &shouldRetry);
				
				if (shouldRetry) retryHandler();
				if (notifyDelegate) notifyDelegateHandler();

			} copy] autorelease]);
			
			CFDictionaryAddValue(failureHandlers, connection, [[^ {
			
				BOOL shouldRetry = NO, notifyDelegate = NO;
				
				if (inFailureHandler)
				inFailureHandler(self, [NSDictionary dictionary], &notifyDelegate, &shouldRetry);
				
				if (shouldRetry) retryHandler();
				if (notifyDelegate) notifyDelegateHandler();
			
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





- (NSDictionary *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil {

	NSMutableDictionary *arguments = [NSMutableDictionary dictionary];

	if (inArgumentsOrNil) for (id argumentKey in [inArgumentsOrNil keysOfEntriesPassingTest:^(id key, id object, BOOL *stop) {
	
		if ([object isEqual:@""]) return NO;
		if ([object isEqual:[NSNull null]]) return NO;
		
		return YES;
	
	}]) [arguments setObject:[inArgumentsOrNil objectForKey:argumentKey] forKey:argumentKey];		

	
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

	return [[transformedContext copy] autorelease];

}

- (NSDictionary *) requestContextByTransformingContext:(NSDictionary *)inContext forMethodNamed:(NSString *)inMethodName {

	return IRWebAPITransformedContextFromTransformerArraysGet(inContext, [NSArray arrayWithObjects:
		
		self.globalRequestPreTransformers,
		[self requestTransformersForMethodNamed:inMethodName],
		self.globalRequestPostTransformers,
	
	nil]);

}

- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse forMethodNamed:(NSString *)inMethodName {

	return IRWebAPITransformedContextFromTransformerArraysGet(inResponse, [NSArray arrayWithObjects:

		self.globalResponsePreTransformers,
		[self responseTransformersForMethodNamed:inMethodName],
		self.globalResponsePostTransformers,

	nil]);

}





- (NSURLRequest *) requestWithContext:(NSDictionary *)inContext {

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:IRWebAPIRequestURLWithQueryParameters(
	
		(NSURL *)[inContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL],
		[inContext objectForKey:kIRWebAPIEngineRequestHTTPQueryParameters]
	
	) cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
	
	NSDictionary *headerFields;
	if (headerFields = [inContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields])
	for (NSString *headerFieldKey in headerFields)
	[request setValue:[headerFields objectForKey:headerFieldKey] forHTTPHeaderField:headerFieldKey];
	
	NSData *httpBody = [inContext objectForKey:kIRWebAPIEngineRequestHTTPBody];
	if (![httpBody isEqual:[NSNull null]])
	[request setHTTPBody:httpBody];
	
	[request setHTTPMethod:[inContext objectForKey:kIRWebAPIEngineRequestHTTPMethod]];
	
	return [[request copy] autorelease];

}





@end
