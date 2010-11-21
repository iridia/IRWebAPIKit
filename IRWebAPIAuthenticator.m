//
//  IRWebAPIAuthenticator.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"
#import "IRWebAPIAuthenticator.h"





@implementation IRWebAPIAuthenticator
@synthesize engine, globalRequestTransformerBlock, globalResponseTransformerBlock, currentCredentials;

- (id) initWithEngine:(IRWebAPIEngine *)inEngine {

	self = [super init]; if (!self) return nil;
	
	engine = inEngine;
	currentCredentials = nil;
	
	[self createTransformerBlocks];
	
	[self associateWithEngine:engine];
	
	return self;

}

- (void) createTransformerBlocks {

	NSLog(@"-createTransformerBlocks is to be implemented by a subclass.");

}

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine {

	if (self.globalRequestTransformerBlock)
	[self.engine.globalRequestTransformers addObject:self.globalRequestTransformerBlock];

	if (self.globalResponseTransformerBlock)
	[self.engine.globalResponseTransformers addObject:self.globalResponseTransformerBlock];	

}

- (void) disassociateEngine {

	if (self.globalRequestTransformerBlock)
	[self.engine.globalRequestTransformers removeObject:self.globalRequestTransformerBlock];

	if (self.globalResponseTransformerBlock)
	[self.engine.globalResponseTransformers removeObject:self.globalResponseTransformerBlock];
	
	self.engine = nil;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	NSLog(@"-authenticateCredentials:withEngine:onSuccess:onFailure: is to be implemented by a subclass.");

}

@end
