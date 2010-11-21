//
//  IRWebAPIAuthenticator.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//


@class IRWebAPIEngine, IRWebAPICredentials;
@interface IRWebAPIAuthenticator : NSObject {

	IRWebAPIEngine *engine;

//	In -associateWithEngine, these blocks are made and injected into a particular engine.

	IRWebAPITransformer globalRequestTransformerBlock;
	IRWebAPITransformer globalResponseTransformerBlock;
	
	IRWebAPICredentials *currentCredentials;

}

- (id) initWithEngine:(IRWebAPIEngine *)inEngine;

@property (nonatomic, assign, readonly) IRWebAPIEngine *engine;
@property (nonatomic, assign, readonly)	IRWebAPICredentials *currentCredentials;

@end





@interface IRWebAPIAuthenticator ()

- (void) createTransformerBlocks;

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine;
- (void) disassociateEngine;

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler;

@property (nonatomic, assign, readwrite) IRWebAPIEngine *engine;
@property (nonatomic, assign, readwrite) IRWebAPITransformer globalRequestTransformerBlock;
@property (nonatomic, assign, readwrite) IRWebAPITransformer globalResponseTransformerBlock;
@property (nonatomic, assign, readwrite) IRWebAPICredentials *currentCredentials;

@end




