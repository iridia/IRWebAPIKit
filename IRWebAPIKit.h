//
//  IRWebAPIKit.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>





@class IRWebAPIEngine;
@class IRWebAPIContext;
@class IRWebAPIAuthenticator;
@class IRWebAPIInterface;





typedef NSDictionary * (^IRWebAPIResponseParser) (NSData *inData);

typedef NSDictionary * (^IRWebAPITransformer) (NSDictionary *inOriginalContext);

typedef void (^IRWebAPICallback) (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry);

typedef void (^IRWebAPIAuthenticatorCallback) (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry);

typedef void (^IRWebAPIEngineExecutionBlock) (void);





//	The dictionary that a IRWebAPITransformer block gets will contain these keys:

#define kIRWebAPIEngineRequestHTTPBaseURL @"IRWebAPIEngineRequestHTTPBaseURL"
//	Expected to be a NSURL, and well it should be there

#define kIRWebAPIEngineRequestHTTPHeaderFields @"IRWebAPIEngineHTTPHeaderFields"
//	Expected to be a dictionary

#define kIRWebAPIEngineRequestHTTPPOSTParameters @"IRWebAPIEngineRequestHTTPPOSTParameters"
//	Expected to be a dictionary, that contains NSString / NSData objects.  Everything is in utf-8 or octet.
//	If not blank, IRWebAPIEngine makes the HTTP body from the parameters.
//	Notice that to use POST parameters, a new transformer block that grabs the correct stuff under this key from the context and adds it to the 

#define kIRWebAPIEngineRequestHTTPBody @"IRWebAPIEngineHTTPBody"
//	Expected to be NSData, or [NSNull null] for custom HTTP body handling.
//	If used with IRWebAPIEngineRequestHTTPPOSTParameters, an exception will be thrown.

#define kIRWebAPIEngineRequestHTTPQueryParameters @"IRWebAPIEngineHTTPQueryParameters"
//	Expected to be a dictionary

#define kIRWebAPIEngineRequestHTTPMethod @"IRWebAPIEngineRequestHTTPMethod"
//	Expected to be POST, GET, whatever.  Must be POST if IRWebAPIEngineHTTPPOSTParameters is defined.

#define kIRWebAPIEngineParser @"IRWebAPIEngineParser"
//	Expected to be a IRWebAPIResponseParser.  Exposed to allow custom response parsing for “some methods”.





#import "IRWebAPIResponseParser.h"
#import "IRWebAPIHelpers.h"

#import "IRWebAPIEngine.h"
#import "IRWebAPIContext.h"
#import "IRWebAPIAuthenticator.h"
#import "IRWebAPICredentials.h"
#import "IRWebAPIInterface.h"

#import "IRWebAPIInterfaceAuthenticating.h"
#import "IRWebAPIInterfaceXOAuthAuthenticating.h"

#import "IRWebAPIInterfaceURLShortening.h"

#import "IRWebAPIGoogleReaderAuthenticator.h"
#import "IRWebAPIXOAuthAuthenticator.h"

#import "IRWebAPITwitterInterface.h"
#import "IRWebAPIGoogleReaderInterface.h"




