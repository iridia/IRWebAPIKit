//	IRWebAPIEngine
//	Evadne Wu at Iridia, 2010










@interface IRWebAPIEngineContext : CPObject {

	CPURL host @accessors;

}

+ (IRWebAPIEngineContext) contextWithHost:(CPURL)host;

@end










@interface IRWebAPIEngineDelegate
	
- (Function) transformationForMethodCallNamed:(CPString)methodName engine:(IRWebAPIEngine)engine;
- (Function) transformationForMethodResponseNamed:(CPString)methodName engine:(IRWebAPIEngine)engine;

@end










@interface IRWebAPIEngine : CPObject {

	BOOL isBusy @accessors(readonly);
	id delegate @accessors;

}

+ (IRWebAPIEngine) engineWithContext:(IRWebAPIEngineContext);
- (IRWebAPIEngine) initWithContext:(IRWebAPIEngineContext);

- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)methodParameters;

- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)methodParameters onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure;

- (void) fireAPIRequestNamed:(CPString)methodName withArguments:(CPDictionary)methodParameters onSuccess:(Function)callbackOnSuccess failure:(Function)callbackOnFailure cacheResponse:(BOOL)cacheResponse notifyDelegate:(BOOL)notifyDelegate;

@end









