//
//  IRWebAPIKitTestOAuthHelpers.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/13/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKitTestOAuthHelpers.h"


@implementation IRWebAPIKitTestOAuthHelpers

- (void) testOAuthBaseSignatureString {

//	STAssertTrue(NO, @"Being a prank");

	NSLog(
	
		@"Test Base String %@",
		IRWebAPIKitOAuthSignatureBaseStringMake(@"POST", [NSURL URLWithString:@"/users/lookup.json" relativeToURL:[NSURL URLWithString:@"https://api.twitter.com"]], nil)
		
	);

}

@end
