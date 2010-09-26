//	IRWebAPIKit.j
//	Evadne Wu at Iridia, 2010'
	
	
	
	

	@import <Foundation/Foundation.j>
	@import <AppKit/AppKit.j>
	@import <IRDelegation/IRDelegation.j>
	
	@import "IRWebAPIEngine.j"
	@import "IRWebAPIContext.j"
	
//	Working on…	
	@import "IRSiteReachability.j"
	
//	Mock!
	@import "IRWebAPIMockJSONPConnection.j"
	
	
	
	
	
	//	Time to talk about how this tool works:
	//
	//	1.	Be flat in what you send, be three-dimensional in what you get.
	//	2.	Give JSON, take JSON.  Give Objects, take Objects.
	//	3.	Register transformations in your initializer.  Don’t do ad-hoc transformations.
	
	
	
	
	