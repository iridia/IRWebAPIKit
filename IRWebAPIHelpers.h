//
//  IRWebAPIHelpers.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRWebAPIKit.h"
#import <CoreFoundation/CoreFoundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import <UIKit/UIDevice.h>

#ifndef IRWebAPIHelpersSection
#define IRWebAPIHelpersSection





static inline NSString * IRWebAPIKitRFC3986EncodedStringMake (NSString *inString) {

//	http://mesh.typepad.com/blog/2007/10/url-encoding-wi.html

	NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" , @"@" , @"&" , @"=" , @"+" , @"$" , @"," , @"[" , @"]", @"#", @"!", @"'", @"(", @")", @"*", nil];

	NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" , @"%3A" , @"%40" , @"%26" , @"%3D" , @"%2B" , @"%24" , @"%2C" , @"%5B" , @"%5D",  @"%23", @"%21", @"%27", @"%28", @"%29", @"%2A", nil];

	int len = [escapeChars count];
	NSMutableString *temp = [inString mutableCopy];

	int i;
	
	for(i = 0; i < len; i++)
        [temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i] withString:[replaceChars objectAtIndex:i] options:NSLiteralSearch range:NSMakeRange(0, [temp length])];

	return [NSString stringWithString:temp];

}





static inline NSString * IRWebAPIKitOAuthParameterStringMake (NSString *inString) {

//	From Google’s GData Toolkit
//	http://oauth.net/core/1.0a/#encoding_parameters

	CFStringRef originalString = (CFStringRef)inString;

	CFStringRef leaveUnescaped = CFSTR("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._~");
	CFStringRef forceEscaped =  CFSTR("%!$&'()*+,/:;=?@");

	CFStringRef escapedStr = NULL;

	if (inString) {

		escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalString, leaveUnescaped, forceEscaped, kCFStringEncodingUTF8);
		
		[(id)CFMakeCollectable(escapedStr) autorelease];

	}

	return (NSString *)escapedStr;
	
}





static inline NSString * IRWebAPIKitOAuthSignatureBaseStringMake (NSString *inHTTPMethod, NSURL *inBaseURL, NSDictionary *inQueryParameters) {

	NSString * (^uriEncode) (NSString *) = ^ NSString * (NSString *inString) {

		return IRWebAPIKitRFC3986EncodedStringMake(inString);
	//	return [inString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	
	};

	NSMutableString *returnedString = [NSMutableString string];
	
	[returnedString appendString:inHTTPMethod];
	[returnedString appendString:@"&"];
	[returnedString appendString:uriEncode([inBaseURL absoluteString])];
	
	if ([inQueryParameters count] != 0) {
	
		NSArray *sortedQueryParameterKeys = [[inQueryParameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
		
		NSMutableArray *encodedQueryParameters = [NSMutableArray array];
		
		for (NSString *queryParameterKey in sortedQueryParameterKeys) {
		
			[encodedQueryParameters addObject:[NSString stringWithFormat:@"%@%@%@",
			
				uriEncode(queryParameterKey),
				@"%3D",
				uriEncode([inQueryParameters objectForKey:queryParameterKey])
				
			]];
					
		}
		
		[returnedString appendString:@"&"];
		[returnedString appendString:[encodedQueryParameters componentsJoinedByString:@"%26"]];

	}
	
	return returnedString;

}





static inline NSString *IRWebAPIKitBase64StringFromNSDataMake (NSData *inData) {

//	Cyrus Najmabadi
//	Elegent little encoder
//	http://www.cocoadev.com/index.pl?BaseSixtyFour

//	From Google’s GData Toolkit

	if (inData == nil) return nil;

	const uint8_t* input = [inData bytes];
	NSUInteger length = [inData length];

	NSUInteger bufferSize = ((length + 2) / 3) * 4;
	NSMutableData* buffer = [NSMutableData dataWithLength:bufferSize];

	uint8_t* output = [buffer mutableBytes];

	static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	for (NSUInteger i = 0; i < length; i += 3) {

		NSInteger value = 0;
		
		for (NSUInteger j = i; j < (i + 3); j++) {

			value <<= 8;

			if (j < length)
			value |= (0xFF & input[j]);

		}

		NSInteger idx = (i / 3) * 4;
		output[idx + 0] =                    table[(value >> 18) & 0x3F];
		output[idx + 1] =                    table[(value >> 12) & 0x3F];
		output[idx + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
		output[idx + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';

	}

	return [[[NSString alloc] initWithData:buffer encoding:NSASCIIStringEncoding] autorelease];

}





static inline NSString *IRWebAPIKitHMACSHA1 (NSString *inConsumerSecret, NSString *inTokenSecret, NSString *inPayload) {

//	From Google’s GData Toolkit

	NSString *encodedConsumerSecret = IRWebAPIKitOAuthParameterStringMake(inConsumerSecret);
	NSString *encodedTokenSecret = IRWebAPIKitOAuthParameterStringMake(inTokenSecret);

	NSString *key = [NSString stringWithFormat:@"%@&%@",
	
		encodedConsumerSecret ? encodedConsumerSecret : @"",
		encodedTokenSecret ? encodedTokenSecret : @""
		
	];
	
	NSMutableData *sigData = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
	
	CCHmac(
	
		kCCHmacAlgSHA1,

		[key UTF8String], [key length],
		[inPayload UTF8String], [inPayload length],
		[sigData mutableBytes]
	 
	);
	
	return IRWebAPIKitBase64StringFromNSDataMake(sigData);
  
}





static inline NSString *IRWebAPIKitTimestamp () {

	return [NSString stringWithFormat:@"%d", time(NULL)];

}





static inline NSString *IRWebAPIKitNonce () {

	NSString *uuid = nil;
	CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);

	if (!theUUID) return nil;

	uuid = NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
	CFRelease(theUUID);
	
	return [NSString stringWithFormat:@"%@-%@", IRWebAPIKitTimestamp(), uuid, [UIDevice currentDevice].uniqueIdentifier];
	
	return uuid;

}





#endif