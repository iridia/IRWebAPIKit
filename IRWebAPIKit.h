//
//  IRWebAPIKit.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//





#if 0

	#define IRWebAPIKitLog( s, ... ) NSLog( @"<%s : (%d)> %@",__FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#else

	#define IRWebAPIKitLog( s, ... ) 

#endif





#ifndef __IRWebAPITransformer__
#define __IRWebAPITransformer__





#import <Foundation/Foundation.h>





@class IRWebAPIEngine;
@class IRWebAPIContext;
@class IRWebAPIAuthenticator;
@class IRWebAPIInterface;





#pragma mark Blocks

typedef NSDictionary * (^IRWebAPIResponseParser) (NSData *inData);

//	The parser makes a dictionary from a NSData.


typedef NSDictionary * (^IRWebAPIRequestContextTransformer) (NSDictionary *inOriginalContext);

//	The transformer returns a transformed context dictionary.


typedef BOOL (^IRWebAPIResposeValidator) (NSDictionary *inResponseOrNil);

//	The validator returns a BOOL regarding to the parsed and transformed response.


typedef void (^IRWebAPICallback) (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry);

//	The callback takes an engine and a response, then optionally tells the engine whether to notify its delegate or retry.
//	inResponseContext contains lower-level objects, like NSURLResponse.
//	*&outNotifyDelegate defaults to YES
//	*&outShouldRetry defaults to NO


typedef void (^IRWebAPIAuthenticatorCallback) (IRWebAPIAuthenticator *inAuthenticator, BOOL isAuthenticated, BOOL *inShouldRetry);

//	The authenticator callback takes an authenticator, and its authentication status.
//	If necessary, the block works with the authenticator and can tell it to retry authenticating.


typedef void (^IRWebAPIInterfaceCallback) (NSDictionary *inResponseOrNil, BOOL *outNotifyDelegate, BOOL *outShouldRetry);

//	The callback takes the response, then optionally tells the interface whether to notify its delegate or retry.


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





#pragma mark IRWebAPIEngine Response Context Dictionary Keys

#define kIRWebAPIEngineResponseContextURLResponseName @"kIRWebAPIEngineResponseContextURLResponseName"

//	We send a response context to IRWebAPICallback blocks; this key gets the original response which contains useful information e.g. the return code.





#import "IRWebAPIResponseParser.h"
#import "IRWebAPIKitEntityDefines.h"
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





#endif




