//	IRSiteReachability.j
//	Evadne Wu at Iridia, 2010
	
	
	
	

var	_IRSiteReachabilityResult = nil;

var	kIRSiteReachabilityResultUnknown = @"IRSiteReachabilityResultUnknown",
	kIRSiteReachabilityResultReachable = @"IRSiteReachabilityResultReachable",
	kIRSiteReachabilityResultUnavailable = @"IRSiteReachabilityResultUnavailable";
	
	
	
	





	
@implementation IRSiteReachability : CPObject {
	
}

+ (IRSiteReachabilityType) status {
	
	return _IRSiteReachabilityResult;
	
}

@end