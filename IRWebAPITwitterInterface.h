//
//  IRWebAPITwitterInterface.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/1/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

#ifndef __IRWebAPITwitterInterface__
#define __IRWebAPITwitterInterface__

typedef NSUInteger IRWebAPITwitterStatusIdentifier;
#define IRWebAPITwitterStatusIdentifierNotApplicable 0;


typedef struct IRWebAPITwitterStatusIdentifierRange {
	
	IRWebAPITwitterStatusIdentifier begin;
	IRWebAPITwitterStatusIdentifier end;
	
} IRWebAPITwitterStatusIdentifierRange;


static inline IRWebAPITwitterStatusIdentifierRange IRWebAPITwitterStatusIdentifierRangeMake (IRWebAPITwitterStatusIdentifier begin, IRWebAPITwitterStatusIdentifier end) {
	
	IRWebAPITwitterStatusIdentifierRange returnedRange;

	returnedRange.begin = begin;
	returnedRange.end = end;
	
	return returnedRange;
	
}


#endif





@interface IRWebAPITwitterInterface : IRWebAPIInterface <IRWebAPIInterfaceAuthenticating, IRWebAPIInterfaceXOAuthAuthenticating>

- (void) updateStatusForCurrentUserWithContents:(NSString *)inContents userinfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPICallback)inSuccessCallback onFailure:(IRWebAPICallback)inFailureCallback;

@end





#import "IRWebAPITwitterInterface+Timeline.h"
#import "IRWebAPITwitterInterface+Geo.h"




