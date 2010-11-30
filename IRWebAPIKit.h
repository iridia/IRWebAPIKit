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

#define kIRWebAPIEngineRequestHTTPBody @"IRWebAPIEngineHTTPBody"
//	Expected to be NSData or nil

#define kIRWebAPIEngineRequestHTTPQueryParameters @"IRWebAPIEngineHTTPQueryParameters"
//	Expected to be a dictionary

#define kIRWebAPIEngineRequestHTTPMethod @"IRWebAPIEngineRequestHTTPMethod"
//	Expected to be POST, GET, whatever

#define kIRWebAPIEngineParser @"IRWebAPIEngineParser"
//	Expected to be a IRWebAPIResponseParser.  Exposed to allow custom response parsing for “some methods”.





#import "IRWebAPIResponseParser.h"
#import "IRWebAPIHelpers.h"

#import "IRWebAPIEngine.h"
#import "IRWebAPIContext.h"
#import "IRWebAPIAuthenticator.h"
#import "IRWebAPICredentials.h"
#import "IRWebAPIInterface.h"

#import "IRWebAPIGoogleReaderAuthenticator.h"
#import "IRWebAPIXOAuthAuthenticator.h"

#import "IRWebAPIInterfaceXOAuthInterfaceProtocol.h"
#import "IRWebAPITwitterInterface.h"




