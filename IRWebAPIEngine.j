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

var	kIRWebAPIEngineConnectionTimeoutTimeIntervalUserInfoDictionaryKey = @"IRWebAPIEngineConnectionTimeoutTimeInterval";

var 	kIRWebAPIEngineSerializationSchemeKeyOrdinaryFlat = "IRWebAPIEngineSerializationSchemeOrdinaryFlat";

var	kIRWebAPIEngineConnectionDidReceiveDataNotification = @"IRWebAPIEngineConnectionDidReceiveDataNotification",
	kIRWebAPIEngineConnectionDidFailNotification = @"IRWebAPIEngineConnectionDidFailNotification";





@class IRWebAPIContext;





@implementation IRWebAPIEngine : CPObject {

	IRWebAPIContext context;

	id delegate @accessors;
	
	CPMutableSet aliveConnections;				//	Collects connections
	
	CPMutableDictionary requestArgumentTransformations;	//	Key is method name
	CPMutableDictionary responseTransformations;		//	Key is method name
	
	CPMutableDictionary successHandlersForConnections;	//	Key is connection UID
	CPMutableDictionary failureHandlersForConnections;	//	Key is connection UID
	
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
	
	[self addConnectionToTheActiveSet:connection];
	[connection start];
	
	var connectionTimeout /* (CPTimeinterval) */ = parseFloat(
		
			[[[CPBundle mainBundle] infoDictionary] objectForKey:kIRWebAPIEngineConnectionTimeoutTimeIntervalUserInfoDictionaryKey]
			
	) || 10.0;
	
	[self performSelector:@selector(purgeConnectionAndSendFailureNotificationIfAppropriate:) withObject:connection afterDelay:connectionTimeout];
	
}





- (void) connection:(CPJSONPConnection)connection didReceiveData:(CPString)data {

	[self removeConnectionFromTheActiveSet:connection];

	var successHandler = [successHandlersForConnections objectForKey:[connection UID]];
	
	if (successHandler) {
		
		successHandler(data);
		[successHandlersForConnections removeObjectForKey:[connection UID]];
		
	} else {
				
		[[CPNotificationCenter defaultCenter] postNotificationName:kIRWebAPIEngineConnectionDidReceiveDataNotification object:nil userInfo:data];
		
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
	
	//	Remove.  Notice that messaging nil is okay
	
	[aliveConnections removeObject:connection];
	
}





- (void) purgeConnectionAndSendFailureNotificationIfAppropriate:(CPTimer)sender {
	
	var connection = [sender userInfo];
		
//	If this connection is not in the active set, it has already been inactive
//	That means so this method is called by a leftover timer
	
	if (![aliveConnections containsObject:connection]) return;


//	Pose as the connection itself and send ourself a delegate message
//	Because we have already implemented the handling here	

	[connection cancel];
	[self connection:connection didFailWithError:null];
	
}





@end




