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

@end




