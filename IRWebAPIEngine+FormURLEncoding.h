//
//  IRWebAPIEngine+FormURLEncoding.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IRWebAPIEngine.h"

extern NSString * const kIRWebAPIEngineRequestContextFormURLEncodingFieldsKey;

NSData * IRWebAPIEngineFormURLEncodedDataWithDictionary (NSDictionary *dictionary);

@interface IRWebAPIEngine (FormURLEncoding)

+ (IRWebAPIRequestContextTransformer) defaultFormURLEncodingTransformer;

@end
