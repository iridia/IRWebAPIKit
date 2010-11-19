//
//  IRWebAPIContext.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIContext.h"





@implementation IRWebAPIContext

@synthesize baseURL;

- (id) initWithBaseURL:(NSURL *)inBaseURL {

	self = [super init]; if (!self) return nil;
	
	baseURL = [inBaseURL retain];
	
	return self;

}

- (id) init {

	return [self initWithBaseURL:nil];

}





- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName {

	return [NSURL URLWithString:inMethodName relativeToURL:self.baseURL];

}

@end




