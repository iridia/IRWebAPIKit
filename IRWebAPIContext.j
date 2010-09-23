//	IRWebAPIContext.j
//	Evadne Wu at Iridia, 2010





@class IRWebAPIEngine;





@implementation IRWebAPIContext : CPObject {

	CPURL baseURL @accessors;

}

+ (IRWebAPIContext) contextWithBaseURL:(CPURL)inURL {

	CPLog(@"IRWebAPIContext contextWithBaseURL called");
	
	return [[[self class] alloc] initWithBaseURL:inURL];
	
}

//- (CPURL) absoluteURLForRequest:()

- (IRWebAPIContext) initWithBaseURL:(CPURL)inURL {
	
	self = [super init]; if (self == nil) return nil;
	
	[self setBaseURL:inURL];
	
	return self;
	
}

@end




