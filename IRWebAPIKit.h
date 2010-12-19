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





#pragma mark Blocks

typedef NSDictionary * (^IRWebAPIResponseParser) (NSData *inData);

//	The parser makes a dictionary from a NSData.


typedef NSDictionary * (^IRWebAPITransformer) (NSDictionary *inOriginalContext);

//	The transformer returns a transformed context dictionary.


typedef BOOL (^IRWebAPIResposeValidator) (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil);

//	The validator returns a BOOL regarding to the parsed and transformed response.


typedef void (^IRWebAPICallback) (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *outNotifyDelegate, BOOL *outShouldRetry);

//	The callback takes an engine and a response, then optionally tells the engine whether to notify its delegate or retry.
//	*&outNotifyDelegate defaults to YES
//	*&outShouldRetry defaults to NO


typedef void (^IRWebAPIAuthenticatorCallback) (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry);

//	The authenticator callback takes an authenticator, and its authentication status.
//	If necessary, the block works with the authenticator and can tell it to retry authenticating.


typedef void (^IRWebAPIEngineExecutionBlock) (void);

//	Internal.





#pragma mark IRWebAPITransformer Context Dictionary Keys

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




