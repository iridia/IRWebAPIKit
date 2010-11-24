//
//  IRWebAPIKeychainedCredentials.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/24/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPICredentials.h"





@interface IRWebAPIKeychainedCredentials : IRWebAPICredentials {

	NSString *keychainIdentifier;
	NSString *keychainSecret;

}

@property (nonatomic, readwrite, retain) NSString *keychainIdentifier;
@property (nonatomic, readwrite, retain) NSString *keychainSecret;

- (void) persistKeychainPayloadWithError:(NSError **)inErrorOrNil;
- (void) restoreKeychainPayload;

@end




