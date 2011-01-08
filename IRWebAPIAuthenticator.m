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
@synthesize engine, globalRequestPreTransformerBlock, globalRequestPostTransformerBlock, globalResponsePreTransformerBlock, globalResponsePostTransformerBlock, currentCredentials;

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

- (void) dealloc {

	self.globalRequestPreTransformerBlock = nil;
	self.globalRequestPostTransformerBlock = nil;
	self.globalResponsePreTransformerBlock = nil;
	self.globalResponsePostTransformerBlock = nil;

	[super dealloc];

}

- (void) associateWithEngine:(IRWebAPIEngine *)inEngine {

	if (self.globalRequestPreTransformerBlock)
	[self.engine.globalRequestPreTransformers addObject:self.globalRequestPreTransformerBlock];
	
	if (self.globalRequestPostTransformerBlock)
	[self.engine.globalRequestPostTransformers addObject:self.globalRequestPostTransformerBlock];

	if (self.globalResponsePreTransformerBlock)
	[self.engine.globalResponsePreTransformers addObject:self.globalResponsePreTransformerBlock];
	
	if (self.globalResponsePostTransformerBlock)
	[self.engine.globalResponsePostTransformers addObject:self.globalResponsePostTransformerBlock];

}

- (void) disassociateEngine {

	if (self.globalRequestPreTransformerBlock)
	[self.engine.globalRequestPreTransformers removeObject:self.globalRequestPreTransformerBlock];
	
	if (self.globalRequestPostTransformerBlock)
	[self.engine.globalRequestPostTransformers removeObject:self.globalRequestPostTransformerBlock];

	if (self.globalResponsePreTransformerBlock)
	[self.engine.globalResponsePreTransformers removeObject:self.globalResponsePreTransformerBlock];
	
	if (self.globalResponsePostTransformerBlock)
	[self.engine.globalResponsePostTransformers removeObject:self.globalResponsePostTransformerBlock];
	
	self.engine = nil;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler {

	NSLog(@"-authenticateCredentials:withEngine:onSuccess:onFailure: is to be implemented by a subclass.");

}

@end
