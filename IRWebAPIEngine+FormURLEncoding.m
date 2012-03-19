//
//  IRWebAPIEngine+FormURLEncoding.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IRWebAPIHelpers.h"
#import "IRWebAPIEngine+FormURLEncoding.h"

NSString * const kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey = @"IRWebAPIEngineRequestContextFormURLEncodingFields";

@implementation IRWebAPIEngine (FormURLEncoding)

+ (IRWebAPIRequestContextTransformer) defaultFormURLEncodingTransformer {

	return [[(^ (NSDictionary *inOriginalContext) {
	
		NSDictionary *formNamesToContents = [inOriginalContext objectForKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey];
		
		if (![formNamesToContents count])
			return inOriginalContext;
		
		NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
		NSMutableDictionary *headerFields = [returnedContext objectForKey:kIRWebAPIEngineRequestHTTPHeaderFields];
		
		if (!headerFields) {
			headerFields = [NSMutableDictionary dictionary];
			[returnedContext setObject:headerFields forKey:kIRWebAPIEngineRequestHTTPHeaderFields];
		}
		
		[headerFields setObject:@"8bit" forKey:@"Content-Transfer-Encoding"];
		[headerFields setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
		
		NSMutableData *sentData = [NSMutableData data];
		
		[formNamesToContents enumerateKeysAndObjectsUsingBlock: ^ (id key, id obj, BOOL *stop) {
		
			if ([sentData length])
				[sentData appendData:[@"&" dataUsingEncoding:NSUTF8StringEncoding]];
			
			[sentData appendData:[IRWebAPIKitRFC3986EncodedStringMake(key) dataUsingEncoding:NSUTF8StringEncoding]];
			[sentData appendData:[@"=" dataUsingEncoding:NSUTF8StringEncoding]];
			[sentData appendData:[IRWebAPIKitRFC3986EncodedStringMake(obj) dataUsingEncoding:NSUTF8StringEncoding]];
			
		}];
		
		[returnedContext setObject:sentData forKey:kIRWebAPIEngineRequestHTTPBody];
		
		[returnedContext removeObjectForKey:kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey];
		
		[returnedContext setObject:@"POST" forKey:kIRWebAPIEngineRequestHTTPMethod];
		
		return (NSDictionary *)returnedContext;
	
	}) copy] autorelease];

}

@end
