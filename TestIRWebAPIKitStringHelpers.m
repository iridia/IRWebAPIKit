//
//  TestIRWebAPIKitStringHelpers.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/2/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "TestIRWebAPIKitStringHelpers.h"


@implementation TestIRWebAPIKitStringHelpers

- (void) testHTMLEntitiesDecoding {

	STAssertEqualObjects(IRWebAPIStringByDecodingXMLEntities(@"&lt;"), @"<", @"&lt; -> <");
	
//	(IRWebAPIStringByDecodingXMLEntities(@"&lt;"), @"")

}

@end




