//
//  IRWebAPIKeychainedCredentials.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/24/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKeychainedCredentials.h"


@implementation IRWebAPIKeychainedCredentials

@synthesize keychainIdentifier, keychainSecret;

- (BOOL) persistKeychainPayloadWithError:(NSError **)inErrorOrNil {

//	Throw an error if the identifier exists already

}

- (void) restoreKeychainPayload {

}

@end
