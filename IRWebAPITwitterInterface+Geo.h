//
//  IRWebAPITwitterInterface+Geo.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/15/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface.h"
#import <CoreLocation/CoreLocation.h>

@interface IRWebAPITwitterInterface (Geo)

- (void) reverseGeocodeWithLocation:(CLLocation *)inLocation userinfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPICallback)inSuccessCallback onFailure:(IRWebAPICallback)inFailureCallback;

@end
