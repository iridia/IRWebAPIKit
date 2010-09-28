//	IRWebAPIModel.j
//	Evadne Wu at Iridia, 2010
	
	
	
	
	
@implementation IRWebAPIModel : CPObject {
	
	BOOL loading;

	id delegate @accessors;
	
}





+ (IRProtocol) irDelegateProtocol {
	
	return [IRProtocol protocolWithSelectorsAndOptionalFlags:
	
		@selector(model:didFinishLoadingWithData:), false,
		@selector(model:didFailLoadingWithError:), false,
		@selector(model:shouldReloadFromCachedData:), true
	
	];
	
}





+ (CPString) methodName {

	return nil;
	
}

+ (Function) argumentTransformation {

	return nil;
	
}

+ (Function) responseTransformation {
	
	return nil;
	
}





- (IRWebAPIModel) init {
	
	self = [super init]; if (self == nil) return nil;
	
	loading = NO;
	
	return self;
	
}





- (void) reloadData {
	
	return;
	
}










@end