//	IRWebAPIEngine.j
//	Evadne Wu at Iridia, 2010




	
var kIRWebAPIEngineSerializationSchemes = {
	
//	TODO: Reference http://www.w3.org/TR/html401/interact/forms.html
	
	"IRWebAPIEngineSerializationSchemeOrdinaryFlat": function (inDictionary) {
		
		var	returnString = @"",
			enumerator = [inDictionary keyEnumerator],
			key = nil;
		
		while (key = [enumerator nextObject])
		returnString += @"&" + encodeURIComponent(key) + @"=" + encodeURIComponent([inDictionary objectForKey:key]);
		
		return returnString.replace(/^&/, "");
		
	}
	
};





var	kIRWebAPIEngineConnectionTimeoutTimeIntervalUserInfoDictionaryKey = @"IRWebAPIEngineConnectionTimeoutTimeInterval",
	kIRWebAPIEngineSerializationSchemeKeyOrdinaryFlat = "IRWebAPIEngineSerializationSchemeOrdinaryFlat",
	kIRWebAPIEngineConnectionDidReceiveDataNotification = @"IRWebAPIEngineConnectionDidReceiveDataNotification",
	kIRWebAPIEngineConnectionDidFailNotification = @"IRWebAPIEngineConnectionDidFailNotification";





@class IRWebAPIContext;





@implementation IRWebAPIEngine : CPObject {

	IRWebAPIContext context;
	id delegate @accessors;
	CPMutableSet aliveConnections;


//	Note.  The global transformations could be overriding points for authentication purposes,
//	But if you want to do something XSLT’y, do them in argument / response transformations for every method involved.
	
	CPMutableArray globalArgumentTransformations;		//	Called on all outgoing method invocations
	CPMutableDictionary requestArgumentTransformations;	//	Key is method name
	CPMutableDictionary responseTransformations;		//	Key is method name
	CPMutableArray globalResponseTransformations;		//	Called on all incoming responses
	
	CPMutableDictionary successHandlersForConnections;	//	Key is connection UID
	CPMutableDictionary failureHandlersForConnections;	//	Key is connection UID

	CPMutableDictionary mockResponses;			//	Key is method name, contains mock JS Objects
	
	/* (CPString) */ IRWebAPIEngineSerializationSchemeKey serializationScheme @accessors;
	
	Class connectionClass @accessors;

}





+ (IRProtocol) delegateProtocol {
	
	return [IRProtocol protocolWithSelectorsAndOptionalFlags:
	
		@selector(transformationForMethodCallNamed:engine:), true,
		@selector(transformationForMethodFeedbackNamed:engine:), true
	
	];
	
}





+ (IRWebAPIEngine) engineWithContext:(IRWebAPIContext)inContext {
	
	self = [[self alloc] initWithContext:inContext]; if (self == nil) return nil;
	
	return self;
	
}





- (IRWebAPIEngine) initWithContext:(IRWebAPIContext)inContext {
	
	self = [super init]; if (self == nil) return nil;
	
	context = inContext;
	serializationScheme = kIRWebAPIEngineSerializationSchemeKeyOrdinaryFlat;
	
	globalArgumentTransformations = [CPMutableArray array];
	requestArgumentTransformations = [CPMutableDictionary dictionary];

	globalResponseTransformations = [CPMutableArray array];
	responseTransformations = [CPMutableDictionary dictionary];
	
	successHandlersForConnections = [CPMutableDictionary dictionary];
	failureHandlersForConnections = [CPMutableDictionary dictionary];

//	connectionClass = [IRJSONPMockConnection class];
	connectionClass = [CPJSONPConnection class];
	
	mockResponses = [CPMutableDictionary dictionary];
	
	return self;
	
}





- (void) enqueueGlobalArgumentTransformation:(Function)transformation {
	
	[globalArgumentTransformations addObject:transformation];
	
}

- (void) enqueueArgumentTransformation:(Function)transformation forMethodNamed:(CPString)methodName {
	
	[requestArgumentTransformations setObject:transformation forKey:methodName];
	
}


- (CPDictionary) transformedArguments:(CPDictionary)inArguments forMethodNamed:(CPString)methodName {
	
	var requestObject = [inArguments mutableCopy] || [CPMutableDictionary dictionary];
	
	var enumerator = [globalArgumentTransformations objectEnumerator], globalArgumentTransformation = nil;
	while (globalArgumentTransformation = [enumerator nextObject])
	requestObject = globalArgumentTransformation(requestObject);
	
	var specificArgumentTransformation = [requestArgumentTransformations valueForKey:methodName];
	if (specificArgumentTransformation != nil)
	requestObject = specificArgumentTransformation(requestObject);
	
	return requestObject;
	
}





- (void) enqueueGlobalResponseTransformation:(Function)transformation {
	
	[globalResponseTransformations addObject:transformation];
	
}

- (void) enqueueResponseTransformation:(Function)transformation forMethodNamed:(CPString)methodName {
	
	[responseTransformations setObject:transformation forKey:methodName];
	
}

- (CPDictionary) transformedResponse:(CPDictionary)inResponse forMethodNamed:(CPString)methodName {
	
	var responseObject = [inResponse mutableCopy] || [CPMutableDictionary dictionary];
	
	var enumerator = [globalResponseTransformations objectEnumerator], globalResponseTransformation = nil;
	while (globalResponseTransformation = [enumerator nextObject])
	responseObject = globalResponseTransformation(responseObject);
	
	var specificResponseTransformation = [responseTransformations valueForKey:methodName];
	if (specificResponseTransformation != nil)
	responseObject = specificResponseTransformation(responseObject);
	
	return responseObject;
	
}










- (void) enqueueMockResponse:(Object)response forMethodNamed:(CPString)methodName {
	
	[mockResponses setObject:response forKey:methodName];
	
}

- (id) mockResponseForMethodNamed:(CPString)methodName {
	
	return [mockResponses objectForKey:methodName];
	
}










- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)inArguments {

	[self fireAPIRequestNamed:methodName withArguments:inArguments onSuccess:nil failure:nil];
	
}





- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)inArguments onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure {

//	Obviously caching and delegate notifying are not there yet
	
	[self fireAPIRequestNamed:methodName withArguments:inArguments onSuccess:callbackOnSuccess failure:callbackOnFailure cacheResponse:NO notifyDelegate:NO];
	
}





- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)inArguments onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure cacheResponse:(BOOL)cacheResponse notifyDelegate:(BOOL)notifyDelegate {
	
	var	argumentsToSend = [self transformedArguments:inArguments forMethodNamed:methodName],
		serializer = kIRWebAPIEngineSerializationSchemes[serializationScheme];

	var serializedArguments = serializer(argumentsToSend) + "&callback=${JSONP_CALLBACK}";
	var urlToCall = [context connectionURLForMethodNamed:methodName additions:serializedArguments];
	
	var request = [CPURLRequest requestWithURL:urlToCall];
	var connection = [[connectionClass alloc] initWithRequest:request callback:nil delegate:self startImmediately:NO];
	
	connection.methodName = methodName;
	
	if (callbackOnSuccess != nil)
	[successHandlersForConnections setObject:callbackOnSuccess forKey:[connection UID]];
	
	if (callbackOnFailure != nil)
	[failureHandlersForConnections setObject:callbackOnFailure forKey:[connection UID]];
	

	[self addConnectionToTheActiveSet:connection];
	
	var mockResponseOrNil = [self mockResponseForMethodNamed:methodName];
	if (mockResponseOrNil != null) {
		
		[self connection:methodName didReceiveData:mockResponseOrNil];
		
		return;
		
	}
	
	[connection start];
	
	var connectionTimeout /* (CPTimeinterval) */ = parseFloat(
		
		[[[CPBundle mainBundle] infoDictionary] objectForKey:kIRWebAPIEngineConnectionTimeoutTimeIntervalUserInfoDictionaryKey]
			
	) || 10.0;
	
	[self performSelector:@selector(purgeConnectionAndSendFailureNotificationIfAppropriate:) withObject:connection afterDelay:connectionTimeout];
	
}





- (void) connection:(CPJSONPConnection)connection didReceiveData:(Object)data {

	[self removeConnectionFromTheActiveSet:connection];
	
	var transformedResponse = [self transformedResponse:[CPDictionary dictionaryWithJSObject:data recursively:YES] forMethodNamed:connection.methodName];

	var successHandler = [successHandlersForConnections objectForKey:[connection UID]];
	
	if (successHandler) {
		
		successHandler(transformedResponse);
		[successHandlersForConnections removeObjectForKey:[connection UID]];
		
	} else {
				
		[[CPNotificationCenter defaultCenter] postNotificationName:kIRWebAPIEngineConnectionDidReceiveDataNotification object:nil userInfo:transformedResponse];
		
	}

}






- (void) connection:(CPJSONPConnection)connection didFailWithError:(CPString)error {
	
	[self removeConnectionFromTheActiveSet:connection];

	var failureHandler = [failureHandlersForConnections objectForKey:[connection UID]];
	
	if (failureHandler) {
		
		failureHandler(error);
		[failureHandlersForConnections removeObjectForKey:[connection UID]];
		
	} else {
				
		[[CPNotificationCenter defaultCenter] postNotificationName:kIRWebAPIEngineConnectionDidFailNotification object:nil userInfo:nil];
		
	}
	
}





- (void) addConnectionToTheActiveSet:(CPJSONPConnection)connection {

	if (aliveConnections == nil)
	aliveConnections = [CPMutableSet set];
	
	[aliveConnections addObject:connection];
	
}




- (void) removeConnectionFromTheActiveSet:(CPJSONPConnection)connection {
	
	[aliveConnections removeObject:connection];
	
}





- (void) purgeConnectionAndSendFailureNotificationIfAppropriate:(CPJSONPConnection)connection {
		
//	If this connection is not in the active set, it has already finished, or failed
	
	if (![aliveConnections containsObject:connection]) return;


//	Pose as the connection itself and send ourself a delegate message to clean up residue

	[connection cancel];
	[self connection:connection didFailWithError:null];
	
}





@end




