//
//  IRWebAPIKitTest.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 3/13/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface IRWebAPIKitTest : SenTestCase

- (void) testHTMLEntitiesDecoding;
- (void) testRFC3986StringEncoding;

- (void) testQueryDecoding;

@end
