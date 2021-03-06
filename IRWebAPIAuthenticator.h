//
//  IRWebAPIAuthenticator.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//


@class IRWebAPIEngine, IRWebAPICredentials;
@interface IRWebAPIAuthenticator : NSObject

- (id) initWithEngine:(IRWebAPIEngine *)inEngine;

@property (nonatomic, assign, readonly) IRWebAPIEngine *engine;
@property (nonatomic, retain, readonly)	IRWebAPICredentials *currentCredentials;

@end





@interface IRWebAPIAuthenticator ()

- (void) createTransformerBlocks;

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine;
- (void) disassociateEngine;

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler;

@property (nonatomic, assign, readwrite) IRWebAPIEngine *engine;
@property (nonatomic, copy, readwrite) IRWebAPIRequestContextTransformer globalRequestPreTransformerBlock;
@property (nonatomic, copy, readwrite) IRWebAPIRequestContextTransformer globalRequestPostTransformerBlock;
@property (nonatomic, copy, readwrite) IRWebAPIResponseContextTransformer globalResponsePreTransformerBlock;
@property (nonatomic, copy, readwrite) IRWebAPIResponseContextTransformer globalResponsePostTransformerBlock;
@property (nonatomic, retain, readwrite) IRWebAPICredentials *currentCredentials;

@end




