//
//  IRWebAPIKitDefines.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/23/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>





#ifndef __IRWebAPIKitDefines__
#define __IRWebAPIKitDefines__

typedef enum {

	IRWebAPIInterfaceCallbackStyleConcatenatedCallback, // if writing framework, use this one
	IRWebAPIInterfaceCallbackStyleManyCallbacks // app code and proof of concepts can use this 

} IRWebAPIInterfaceCallbackStyle;

#endif





@class IRWebAPIEngine;
@class IRWebAPIContext;
@class IRWebAPIAuthenticator;
@class IRWebAPIInterface;





#pragma mark Blocks

typedef NSDictionary * (^IRWebAPIResponseParser) (NSData *inData);

//	The parser makes a dictionary from a NSData.


typedef NSDictionary * (^IRWebAPIRequestContextTransformer) (NSDictionary *inOriginalContext);

//	The transformer returns a transformed context dictionary.


typedef NSDictionary * (^IRWebAPIResponseContextTransformer) (NSDictionary *inParsedResponse, NSDictionary *inResponseContext);

//	The transformer returns a transformed context dictionary, and is given a change to reference the response context.
//	The latter is not mutable.


typedef BOOL (^IRWebAPIResposeValidator) (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext);

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

extern NSString * const kIRWebAPIEngineRequestHTTPBaseURL;

//	Expected to be a NSURL, and well it should be there


extern NSString * const kIRWebAPIEngineRequestHTTPHeaderFields;

//	Expected to be a dictionary


extern NSString * const kIRWebAPIEngineRequestHTTPPOSTParameters;

//	Expected to be a dictionary, that contains NSString / NSData objects.  Everything is in utf-8 or octet.
//	If not blank, IRWebAPIEngine makes the HTTP body from the parameters.
//	Notice that to use POST parameters, a new transformer block that grabs the correct stuff under this key from the context and adds it to the 


extern NSString * const kIRWebAPIEngineRequestHTTPBody;

//	Expected to be NSData, or [NSNull null] for custom HTTP body handling.
//	If used with IRWebAPIEngineRequestHTTPPOSTParameters, an exception will be thrown.


extern NSString * const kIRWebAPIEngineRequestHTTPQueryParameters;

//	Expected to be a dictionary


extern NSString * const kIRWebAPIEngineRequestHTTPMethod;

//	Expected to be POST, GET, whatever.  Must be POST if IRWebAPIEngineHTTPPOSTParameters is defined.


extern NSString * const kIRWebAPIEngineParser;

//	Expected to be a IRWebAPIResponseParser.  Exposed to allow custom response parsing for “some methods”.


extern NSString * const kIRWebAPIEngineIncomingMethodName;

//	The string that was passed to -fireMethodNamed:


extern NSString * const kIRWebAPIRequestTimeout;

//	+[NSNumber numberWithDouble:].  Default is 60.






#pragma mark IRWebAPIEngine Response Context Dictionary Keys

extern NSString * const kIRWebAPIEngineResponseContextURLResponse;
extern NSString * const kIRWebAPIEngineResponseContextURLResponseName DEPRECATED_ATTRIBUTE;

//	We send a response context to IRWebAPICallback blocks.
//	This contains the vanilla NSURLResponse object.


extern NSString * const kIRWebAPIEngineResponseContextOriginalRequestContext;
extern NSString * const kIRWebAPIEngineResponseContextOriginalRequestContextName DEPRECATED_ATTRIBUTE;

//	This key gets the original request context.




