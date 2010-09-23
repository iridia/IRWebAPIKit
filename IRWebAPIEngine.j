//	IRWebAPIEngine.j
//	Evadne Wu at Iridia, 2010





@class IRWebAPIContext;





@implementation IRWebAPIEngine : CPObject {

	IRWebAPIContext context;

	BOOL isBusy @accessors;
	id delegate @accessors;

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
	
	return self;
	
}





- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)methodParameters {}

- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)methodParameters onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure {}

- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)methodParameters onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure cacheResponse:(BOOL)cacheResponse notifyDelegate:(BOOL)notifyDelegate {}

@end




