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





static inline NSString * IRWebAPIKitStringValue (id<NSObject> inObject) {

	if (!inObject)
	return [[NSString alloc] initWithString:@""];
	
	if ([inObject isKindOfClass:[NSString class]])
	return (NSString *)inObject;
		
	if ([inObject isKindOfClass:[NSNumber class]])
	return [(NSNumber *)inObject stringValue];
	
	return [inObject description];

}





static inline NSString * IRWebAPIKitRFC3986EncodedStringMake (id<NSObject> inObject) {

	NSString *inString = IRWebAPIKitStringValue(inObject);

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

	NSString *encodedConsumerSecret = IRWebAPIKitRFC3986EncodedStringMake(inConsumerSecret);
	NSString *encodedTokenSecret = IRWebAPIKitRFC3986EncodedStringMake(inTokenSecret);

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
	
	uuid = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, theUUID) autorelease];
	CFRelease(theUUID);
	
	return [NSString stringWithFormat:@"%@-%@-%@", IRWebAPIKitTimestamp(), uuid, [UIDevice currentDevice].uniqueIdentifier];
	
}





static inline NSString *IRWebAPIRequestURLQueryParametersStringMake (NSDictionary *inQueryParameters, NSString *inSeparator) {

	if ((!inQueryParameters) || ([inQueryParameters count] == 0))
	return @"";
	
	NSMutableArray *returnedStringParts = [NSMutableArray array];

	for (NSString *queryParameterKey in inQueryParameters)
	[returnedStringParts addObject:[NSString stringWithFormat:@"%@=%@", 
			
		IRWebAPIKitRFC3986EncodedStringMake(queryParameterKey), 
		IRWebAPIKitRFC3986EncodedStringMake([inQueryParameters objectForKey:queryParameterKey])
		
	]];

	return [returnedStringParts componentsJoinedByString:inSeparator];

}





static inline NSURL *IRWebAPIRequestURLWithQueryParameters (NSURL *inBaseURL, NSDictionary *inQueryParametersOrNil) {

	if (inQueryParametersOrNil == nil) return inBaseURL;
	
	return [NSURL URLWithString:[[inBaseURL absoluteString] stringByAppendingFormat:@"?%@", IRWebAPIRequestURLQueryParametersStringMake(inQueryParametersOrNil, @"&")]];

}





#endif