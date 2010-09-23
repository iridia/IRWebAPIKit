//	IRWebAPIContext.j
//	Evadne Wu at Iridia, 2010





@class IRWebAPIEngine;





@implementation IRWebAPIContext : CPObject {

	CPURL baseURL @accessors;

}	

+ (IRWebAPIContext) contextWithBaseURL:(CPURL)inURL {

	return [[[self class] alloc] initWithBaseURL:inURL];
	
}





- (IRWebAPIContext) initWithBaseURL:(CPURL)inURL {
	
	self = [super init]; if (self == nil) return nil;
	
	[self setBaseURL:inURL];
	
	return self;
	
}





- (CPURL) connectionURLForMethodNamed:(CPString)methodName additions:(CPString)additions {
	
	var baseURLString = String([[self baseURL] absoluteString]);
	baseURLString = baseURLString.replace("#{methodName}", (methodName || ""));
	baseURLString = baseURLString.replace("#{methodArguments}", (additions || ""));
	
	return [CPURL URLWithString:baseURLString];
	
}




- (CPString) description {
	
	return [super description] + @" — " + [baseURL description];
	
}

@end




