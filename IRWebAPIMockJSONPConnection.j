//	IRWebAPIMockJSONPConnection.j
//	Evadne Wu at Iridia, 2010
	
@import <Foundation/CPJSONPConnection.j>

kIRWebAPIMockEndpointGeneralException = @"IRWebAPIMockEndpointGeneralException";





//	Notice that we also will probably set a different timeout tolerance for the API engine.
//	The timeout here is set for mockup purposes only.

var	kIRJSONPMockConnectionTimeoutDefaultTimeInterval = 15.0,
	kIRJSONPMockConnectionTimeoutTimeIntervalInfoDictionaryKey = @"IRJSONPMockConnectionTimeoutDefaultTimeInterval",
	kIRJSONPMockConnectionTimeoutDefaultProbability = 0.05,
	kIRJSONPMockConnectionTimeoutProbabilityInfoDictionaryKey = @"IRJSONPMockConnectionTimeoutProbability";





@implementation IRJSONPMockConnection : CPJSONPConnection {
	
	CPMutableDictionary requestHandlers;
	

//	Simulated timeout	

	CPTimeInterval simulatedTimeoutInterval;
	float simulatedTimeoutProbability;


//	Simulated error
	Object simulatedErroneousResponse;
	float simulatedErroneousResponseProbability;
	
}





- (IRWebAPIMockJSONPConnection) initWithRequest:(CPURLRequest)aRequest callback:(CPString)aString delegate:(id)aDelegate startImmediately:(BOOL)shouldStartImmediately {
	
	if (shouldStartImmediately)
	[CPException raise:kIRWebAPIMockEndpointGeneralException reason:[CPString stringWithFormat:@"To use a mocked connection, startImmediately must be set to false because it works with the monkey-patched connection.methodName property."]];
	
	self = [super initWithRequest:aRequest callback:aString delegate:aDelegate startImmediately:NO];
	
	
	var infoDict = [[CPBundle mainBundle] infoDictionary];
	
	simulatedTimeoutInterval = [infoDict objectForKey:kIRJSONPMockConnectionTimeoutTimeIntervalInfoDictionaryKey] || kIRJSONPMockConnectionTimeoutDefaultTimeInterval;
	
	simulatedTimeoutProbability = [infoDict objectForKey:kIRJSONPMockConnectionTimeoutProbabilityInfoDictionaryKey] || kIRJSONPMockConnectionTimeoutDefaultProbability;
	
	return 	self;
}





- (void) start {
	
	CPLog(@"self.methodName is %@", self.methodName);
	
	if ([self shouldSimulateFailure]) {
		
		CPLog(@"Simulating a connection failure");
		
	} else {
		
		CPLog(@"Simulating a successful connection");
		
	}
	
}





- (void) mockRequestNamed:(CPString)requestName withHandler:(Function)handler {
	
	if ([requestHandlers objectForKey:requestName] !== nil)
	[CPException raise:kIRWebAPIMockEndpointGeneralException reason:[CPString stringWithFormat:@"Mock handler for request named %@ already exists", requestName]];
	
	[requestHandlers addObject:handler forKey:requestName];
	
}





- (BOOL) shouldSimulateFailure {
	
	if (Math.random() < simulatedTimeoutProbability) return YES;
	
	return NO;
	
}





@end




