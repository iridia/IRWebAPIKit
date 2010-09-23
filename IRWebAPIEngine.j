//	IRWebAPIEngine.j
//	Evadne Wu at Iridia, 2010




	
var kIRWebAPIEngineSerializationSchemes = {
	
	"IRWebAPIEngineSerializationSchemeOrdinaryFlat": function (inDictionary) {
		
		var	returnString = @"",
			enumerator = [inDictionary keyEnumerator],
			key = null;
		
		if (key = [enumerator nextObject])
		returnString = key + @"=" + encodeURI([inDictionary objectForKey:key]);
		
		while (key = [enumerator nextObject])
		returnString = returnString + @"&" + key + @"=" + encodeURI([inDictionary objectForKey:key]);
		
		return returnString;
		
	}
	
};

var 	kIRWebAPIEngineSerializationSchemeKeyOrdinaryFlat = "IRWebAPIEngineSerializationSchemeOrdinaryFlat";

var	kIRWebAPIEngineConnectionDidReceiveDataNotification = @"IRWebAPIEngineConnectionDidReceiveDataNotification",
	kIRWebAPIEngineConnectionDidFailNotification = @"IRWebAPIEngineConnectionDidFailNotification";





@class IRWebAPIContext;





@implementation IRWebAPIEngine : CPObject {

	IRWebAPIContext context;

	BOOL isBusy @accessors;
	id delegate @accessors;
	
	CPMutableDictionary requestArgumentTransformations;
	CPMutableDictionary responseTransformations;
	
	CPMutableDictionary successHandlersForConnections;	//	Key is Connection UID;
	CPMutableDictionary failureHandlersForConnections;	//	Key is Connection UID;
	
	/* (CPString) */ IRWebAPIEngineSerializationSchemeKey serializationScheme @accessors;

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
	
	successHandlersForConnections = [CPMutableDictionary dictionary];
	failureHandlersForConnections = [CPMutableDictionary dictionary];
	
	return self;
	
}





- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)inArguments {

	[self fireAPIRequestNamed:methodName withArguments:inArguments onSuccess:nil failure:nil];
	
}





- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)inArguments onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure {

//	Obviously caching and delegate notifying are not there yet
	
	[self fireAPIRequestNamed:methodName withArguments:inArguments onSuccess:callbackOnSuccess failure:callbackOnFailure cacheResponse:NO notifyDelegate:NO];
	
}





- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)inArguments onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure cacheResponse:(BOOL)cacheResponse notifyDelegate:(BOOL)notifyDelegate {
	
	var possibleArgumentTransformer = [requestArgumentTransformations valueForKey:methodName];
	var argumentsToSend = (possibleArgumentTransformer != undefined) ? [possibleArgumentTransformer(inArguments) mutableCopy] : [inArguments mutableCopy];
	
	var serializer = kIRWebAPIEngineSerializationSchemes[serializationScheme];
	var serializedArguments = serializer(argumentsToSend) + "&callback=${JSONP_CALLBACK}";
	
	var urlToCall = [context connectionURLForMethodNamed:methodName additions:serializedArguments];
	
	var request = [CPURLRequest requestWithURL:urlToCall];
	var connection = [[CPJSONPConnection alloc] initWithRequest:request callback:nil delegate:self startImmediately:NO];
	
	if (callbackOnSuccess != nil) [successHandlersForConnections setObject:callbackOnSuccess forKey:[connection UID]];
	if (callbackOnFailure != nil) [failureHandlersForConnections setObject:callbackOnFailure forKey:[connection UID]];
	
	[connection start];
	
}





- (void) connection:(CPJSONPConnection)connection didReceiveData:(CPString)data {

	var successHandler = [successHandlersForConnections objectForKey:[connection UID]];
	
	if (successHandler) {
		
		successHandler(data);
		[successHandlersForConnections removeObjectForKey:[connection UID]];
		
	} else {
				
		[[CPNotificationCenter defaultCenter] postNotificationName:kIRWebAPIEngineConnectionDidReceiveDataNotification object:nil userInfo:data];
		
	}

}






- (void) connection:(CPJSONPConnection)aConnection didFailWithError:(CPString)error {

	var failureHandler = [failureHandlersForConnections objectForKey:[connection UID]];
	
	if (failureHandler) {
		
		failureHandler(data);
		[failureHandlersForConnections removeObjectForKey:[connection UID]];
		
	} else {
				
		[[CPNotificationCenter defaultCenter] postNotificationName:kIRWebAPIEngineConnectionDidFailNotification object:nil userInfo:data];
		
	}
	
}





@end




