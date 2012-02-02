//
//  IRWebAPIHelpers.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIDevice.h>
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CommonCrypto/CommonHMAC.h>


# pragma mark Request Arguments Helpers

extern BOOL IRWebAPIKitValidResponse (id inObject);
extern NSString * IRWebAPIKitStringValue (id<NSObject> inObject);
extern id IRWebAPIKitWrapNil(id inObjectOrNil);
extern id IRWebAPIKitNumberOrNull (NSNumber *aNumber);


# pragma mark Encoding, Decoding and Conversion

extern NSString * IRWebAPIKitRFC3986EncodedStringMake (id<NSObject> inObject);
extern NSString * IRWebAPIKitRFC3986DecodedStringMake (id<NSObject> inObject);
extern NSString * IRWebAPIKitBase64StringFromNSDataMake (NSData *inData);
extern NSString * IRWebAPIStringByDecodingXMLEntities (NSString *inString);


# pragma mark Randomness and Order

extern NSString * IRWebAPIKitTimestamp (void);
extern NSString * IRWebAPIKitNonce (void);


# pragma mark Crypto Helpers

extern NSString * IRWebAPIKitOAuthSignatureBaseStringMake (NSString *inHTTPMethod, NSURL *inBaseURL, NSDictionary *inQueryParameters);
extern NSString * IRWebAPIKitHMACSHA1 (NSString *inConsumerSecret, NSString *inTokenSecret, NSString *inPayload);


# pragma mark Type Helpers

extern NSString * IRWebAPIKitMIMETypeOfExtension (NSString *inExtension);


# pragma mark URL Helpers

extern NSString * IRWebAPIRequestURLQueryParametersStringMake (NSDictionary *inQueryParameters, NSString *inSeparator);
extern NSURL * IRWebAPIRequestURLWithQueryParameters (NSURL *inBaseURL, NSDictionary *inQueryParametersOrNil);
extern NSDictionary *IRQueryParametersFromString (NSString *aQueryString);

