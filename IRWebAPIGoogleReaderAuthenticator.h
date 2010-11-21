//
//  IRWebAPIGoogleReaderAuthenticator.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

@class IRWebAPIAuthenticator;
@interface IRWebAPIGoogleReaderAuthenticator : IRWebAPIAuthenticator {

	NSString *authToken;

}

- (void) authenticateCredentials:(IRWebAPICredentials *)inCredentials onSuccess:(IRWebAPIAuthenticatorCallback)successHandler onFailure:(IRWebAPIAuthenticatorCallback)failureHandler;

@end
