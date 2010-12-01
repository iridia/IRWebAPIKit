//
//  IRWebAPIGoogleReaderInterface.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIGoogleReaderInterface.h"


@implementation IRWebAPIGoogleReaderInterface

- (id) init {

	IRWebAPIContext *googleReaderContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.google.com"]] autorelease];

	IRWebAPIEngine *googleReaderEngine = [[[IRWebAPIEngine alloc] initWithContext:googleReaderContext] autorelease];
	
	googleReaderEngine.parser = IRWebAPIResponseDefaultJSONParserMake();

	IRWebAPIAuthenticator *googleReaderAuthenticator = [[IRWebAPIGoogleReaderAuthenticator alloc] initWithEngine:googleReaderEngine];
		
	self = [self initWithEngine:googleReaderEngine authenticator:googleReaderContext];

	if (!self) return nil;

	return self;

}

@end