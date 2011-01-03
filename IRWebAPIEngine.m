//
//  IRWebAPIEngine.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <objc/runtime.h>
#import "IRWebAPIEngine.h"





@interface IRWebAPIEngine ()

static NSString *kIRWebAPIEngineAssociatedDataStore = @"kIRWebAPIEngineAssociatedDataStore";
static NSString *kIRWebAPIEngineAssociatedSuccessHandler = @"kIRWebAPIEngineAssociatedSuccessHandler";
static NSString *kIRWebAPIEngineAssociatedFailureHandler = @"kIRWebAPIEngineAssociatedFailureHandler";

@property (nonatomic, assign, readwrite) CFMutableDictionaryRef dataStore;
@property (nonatomic, assign, readwrite) CFMutableDictionaryRef successHandlers;
@property (nonatomic, assign, readwrite) CFMutableDictionaryRef failureHandlers;

- (void) setInternalDataStore:(NSData *)inDataStore forConnection:(NSURLConnection *)inConnection;
- (NSData *) internalDataStoreForConnection:(NSURLConnection *)inConnection;

- (void) setInternalSuccessHandler:(void (^)(NSData *inResponse))inSuccessHandler forConnection:(NSURLConnection *)inConnection;
- (void (^)(NSData *inResponse)) internalSuccessHandlerForConnection:(NSURLConnection *)inConnection;

- (void) setInternalFailureHandler:(void (^)(void))inFailureHandler forConnection:(NSURLConnection *)inConnection;
- (void (^)(void)) internalFailureHandlerForConnection:(NSURLConnection *)inConnection;


- (IRWebAPIEngineExecutionBlock) executionBlockForAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil validator:(IRWebAPIResposeValidator)inValidator successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler;

- (void) ensureResponseParserExistence;

- (NSDictionary *) baseRequestContextWithMethodName:(NSString *)inMethodName arguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil;
- (NSDictionary *) requestContextByTransformingContext:(NSDictionary *)inContext forMethodNamed:(NSString *)inMethodName;
- (NSURLRequest *) requestWithContext:(NSDictionary *)inContext;

- (NSDictionary *) parsedResponseForData:(NSData *)inData withContext:(NSDictionary *)inContext;
- (NSDictionary *) responseByTransformingResponse:(NSDictionary *)inResponse forMethodNamed:(NSString *)inMethodName;

- (void) cleanUpForConnection:(NSURLConnection *)inConnection;

@end





@implementation IRWebAPIEngine

@synthesize parser, context, successHandlers, failureHandlers, dataStore;
@synthesize globalRequestPreTransformers, globalRequestPostTransformers, requestTransformers, globalResponsePreTransformers, globalResponsePostTransformers, responseTransformers;





# pragma mark -
# pragma mark Initializationand Memory Management

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





# pragma mark -
# pragma mark Helpers

- (void) ensureResponseParserExistence {
	
	if (self.parser) return;
	
	NSLog(@"Warning: IRWebAPIEngine is designed to work with a parser.  Without one, the response will be sent as a default dictionary.");
	self.parser = IRWebAPIResponseDefaultParserMake();
	
}

- (NSDictionary *) parsedResponseForData:(NSData *)inData withContext:(NSDictionary *)inContext {

	IRWebAPIResponseParser parserBlock = [inContext objectForKey:kIRWebAPIEngineParser];

	NSDictionary *parsedResponse = parserBlock(inData);		
	if (parsedResponse)
	return parsedResponse;

	NSLog(@"Warning: unparsable response.  Resetting returned response to an empty dictionary.");
	NSLog(@"Context: %@", inContext);

	IRWebAPIResponseParser defaultParser = IRWebAPIResponseDefaultParserMake();

	NSDictionary *debugOutput = defaultParser(inData);
	NSLog(@"Default parser returns %@.", debugOutput ? (id<NSObject>)debugOutput : (id<NSObject>)@"- null -");

	return [NSDictionary dictionary];

}

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil successHandler:(IRWebAPICallback)inSuccessHandler failureHandler:(IRWebAPICallback)inFailureHandler {

	dispatch_async(dispatch_get_global_queue(0, 0), [self executionBlockForAPIRequestNamed:inMethodName withArguments:inArgumentsOrNil options:nil validator:nil successHandler:inSuccessHandler failureHandler:inFailureHandler]);
	
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




	
	
# pragma mark -
# pragma mark Core

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
			
			[self setInternalSuccessHandler: ^ (NSData *inResponse) {
			
				NSLog(@"Success!");
					
				BOOL shouldRetry = NO, notifyDelegate = NO;
				
				NSDictionary *parsedResponse = [self parsedResponseForData:inResponse withContext:finalizedContext];
				NSDictionary *transformedResponse = [self responseByTransformingResponse:parsedResponse forMethodNamed:inMethodName];
				
				if ((inValidator != nil) && (!inValidator(self, transformedResponse))) {

					if (inFailureHandler)
					inFailureHandler(self, transformedResponse, &notifyDelegate, &shouldRetry);
									
				} else {
				
					if (inSuccessHandler)
					inSuccessHandler(self, transformedResponse, &notifyDelegate, &shouldRetry);
				
				}
				
				if (shouldRetry) retryHandler();
				if (notifyDelegate) notifyDelegateHandler();

			} forConnection:connection];
			
			
			[self setInternalFailureHandler: ^ {
			
				BOOL shouldRetry = NO, notifyDelegate = NO;
				
				if (inFailureHandler)
				inFailureHandler(self, [NSDictionary dictionary], &notifyDelegate, &shouldRetry);
				
				if (shouldRetry) retryHandler();
				if (notifyDelegate) notifyDelegateHandler();
			
			} forConnection:connection];
			
			
			[self setInternalDataStore:[NSMutableData data] forConnection:connection];
			
		//	objc_setAssociatedObject(connection, kIRWebAPIEngineAssociatedDataStore, @"DataStore!", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
			
			[connection start];
		
		});
	
	};
	
	return [[returnedBlock copy] autorelease];

}





# pragma mark -
# pragma mark Connection Delegation

- (void) connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)inData {

	dispatch_async(dispatch_get_global_queue(0, 0), ^{

		id connectionDataStoreOrNil = (NSData *)CFDictionaryGetValue(self.dataStore, inConnection);
		if (!connectionDataStoreOrNil) return;

		NSMutableData *connectionDataStore = connectionDataStoreOrNil;
		[connectionDataStore appendData:inData];
	
	});

}

- (void) connectionDidFinishLoading:(NSURLConnection *)inConnection {

//	NSLog(@"connection %@, associated data store %@", self, objc_getAssociatedObject(inConnection, kIRWebAPIEngineAssociatedDataStore));

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
	
		[self internalSuccessHandlerForConnection:inConnection]([self internalDataStoreForConnection:inConnection]);
		[self cleanUpForConnection:inConnection];
	
	});
	
}

- (void) connection:(NSURLConnection *)inConnection didFailWithError:(NSError *)error {

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
	
		[self internalFailureHandlerForConnection:inConnection]();
		[self cleanUpForConnection:inConnection];
	
	});

}





# pragma mark -
# pragma mark Associated Objects

//	Notice that blocks are made on the stack so they must be copied before being stored away


- (void) setInternalSuccessHandler:(void (^)(NSData *inResponse))inSuccessHandler forConnection:(NSURLConnection *)inConnection {

	CFDictionarySetValue(self.successHandlers, inConnection, [[inSuccessHandler copy] autorelease]);

}

- (void (^)(NSData *inResponse)) internalSuccessHandlerForConnection:(NSURLConnection *)inConnection {

	return CFDictionaryGetValue(self.successHandlers, inConnection);

}

- (void) setInternalFailureHandler:(void (^)(void))inFailureHandler forConnection:(NSURLConnection *)inConnection {

	CFDictionarySetValue(self.failureHandlers, inConnection, [[inFailureHandler copy] autorelease]);

}

- (void (^)(void)) internalFailureHandlerForConnection:(NSURLConnection *)inConnection {

	return CFDictionaryGetValue(self.failureHandlers, inConnection);

}

- (void) setInternalDataStore:(NSData *)inDataStore forConnection:(NSURLConnection *)inConnection {

	CFDictionarySetValue(self.dataStore, inConnection, inDataStore);

}

- (NSData *) internalDataStoreForConnection:(NSURLConnection *)inConnection {

	return (NSData *)CFDictionaryGetValue(self.dataStore, inConnection);

}

- (void) cleanUpForConnection:(NSURLConnection *)inConnection {

	dispatch_async(dispatch_get_main_queue(), ^{
	
		CFDictionaryRemoveValue(self.successHandlers, inConnection);
		CFDictionaryRemoveValue(self.failureHandlers, inConnection);
		CFDictionaryRemoveValue(self.dataStore, inConnection);
	
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
