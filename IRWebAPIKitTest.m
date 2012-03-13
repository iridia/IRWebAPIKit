//
//  IRWebAPIKitTest.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 3/13/12.
//  Copyright (c) 2012 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKitTest.h"
#import "IRWebAPIHelpers.h"

@implementation IRWebAPIKitTest

- (void) testHTMLEntitiesDecoding {

	NSDictionary *originalToDecoded = [NSDictionary dictionaryWithObjectsAndKeys:
	
		@"<", @"&lt;",
	
	nil];

	for (id aKey in originalToDecoded) {
	
		NSString *libraryDecoded = IRWebAPIStringByDecodingXMLEntities(aKey);
	
		STAssertEqualObjects(
		
			[originalToDecoded objectForKey:aKey], 
			libraryDecoded,
			@"Library-decoded string does not match the sample."
			
		);
		
	}

}

- (void) testRFC3986StringEncoding {

//	Still at odds with this.
	
	NSDictionary *originalToEncoded = [NSDictionary dictionaryWithObjectsAndKeys:
	
		@"%25%21%24%26%27%28%29%2A%2B%2C%2F%3A%3B%3D%3F%40", @"%!$&'()*+,/:;=?@",
	
	nil];

	for (id aKey in originalToEncoded) {
	
		NSString *libraryEncoded = IRWebAPIKitRFC3986EncodedStringMake(aKey);
	
		STAssertEqualObjects(
		
			[originalToEncoded objectForKey:aKey], 
			libraryEncoded,
			@"Library-encoded string does not match the sample."
			
		);
		
		STAssertEqualObjects(
		
			IRWebAPIKitRFC3986DecodedStringMake(libraryEncoded),
			aKey,
			@"Decoded library-encoded string does not match the sample."
		
		);
		
	}

}

- (void) testQueryDecoding {

	NSDictionary *testData = [NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSDictionary dictionaryWithObjectsAndKeys:
		
			@"v", @"k",
		
		nil], @"k=v",	
	
		[NSDictionary dictionaryWithObjectsAndKeys:

			@"v1", @"k1",
			@"", @"k2",

		nil], @"k1=v1&k2=",

		[NSDictionary dictionaryWithObjectsAndKeys:

			@"v1", @"k1",
			@"v2", @"k2",

		nil], @"k1=v1&k2=v2",

		[NSDictionary dictionaryWithObjectsAndKeys:

			@"v1", @"k1",
			@"v2", @"k2",
			@"v3", @"k3",
			@"v4", @"k4",

		nil], @"k1=v1&k2=v2&k3=v3&k4=v4",

	nil];
	
	[testData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		
		STAssertEqualObjects(IRQueryParametersFromString(key), obj, @"Decoded object from string %@ must match structure %@", key, obj);
		
	}];
	
}

@end
