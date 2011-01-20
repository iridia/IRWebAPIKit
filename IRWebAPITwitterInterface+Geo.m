//
//  IRWebAPITwitterInterface+Geo.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/15/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPITwitterInterface+Geo.h"





@implementation IRWebAPITwitterInterface (Geo)





- (void) reverseGeocodeWithLocation:(CLLocation *)inLocation userinfo:(NSDictionary *)inUserInfo onSuccess:(IRWebAPICallback)inSuccessCallback onFailure:(IRWebAPICallback)inFailureCallback {

//	Since Twitter’s implementation is still unreliable, we are using the ol’ reliable Google Maps API here

	IRWebAPIContext *googleMapsContext = [[[IRWebAPIContext alloc] initWithBaseURL:[NSURL URLWithString:@"http://maps.googleapis.com/maps/api/"]] autorelease];
	IRWebAPIEngine *googleMapsEngine = [[[IRWebAPIEngine alloc] initWithContext:googleMapsContext] autorelease];
	googleMapsEngine.parser = IRWebAPIResponseDefaultJSONParserMake();

	[googleMapsEngine fireAPIRequestNamed:@"geocode/json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
	
		[NSString stringWithFormat:@"%f,%f", inLocation.coordinate.latitude, inLocation.coordinate.longitude], @"latlng",
		@"true", @"sensor",
	
	nil] successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		NSLog(@"google success");
	
		if (![[inResponseOrNil valueForKey:@"status"] isEqual:@"OK"]) {
			
			inFailureCallback(inResponseOrNil, inResponseContext, outNotifyDelegate, outShouldRetry);
			return;
		
		}
		
		NSDictionary *resultArray = [inResponseOrNil valueForKey:@"results"];
		for (NSDictionary *resultObject in resultArray) {
		
			NSString *formattedAddress = [resultObject valueForKeyPath:@"formatted_address"];

			if ([formattedAddress isEqual:[NSNull null]])
			continue;
			
			inSuccessCallback([NSDictionary dictionaryWithObject:formattedAddress forKey:@"displayString"], inResponseContext, outNotifyDelegate, outShouldRetry);
			return;
		
		}
	
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		inFailureCallback(inResponseOrNil, inResponseContext, outNotifyDelegate, outShouldRetry);
	
	}];




	return;

	[self.engine fireAPIRequestNamed:@"/geo/reverse_geocode.json" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:

		[NSNumber numberWithFloat:inLocation.coordinate.latitude], @"lat",
		[NSNumber numberWithFloat:inLocation.coordinate.longitude], @"long",
//		inLocation.horizontalAccuracy, @"accuracy",
		@"1000m", @"accuracy",
		@"1", @"max_results",

	nil] options:nil successHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {

		if (
		
			([inResponseOrNil valueForKey:@"errors"] != [NSNull null]) || 
			([[inResponseOrNil valueForKey:@"result.places"] isEqual:[NSNull null]]) || 
			(![[inResponseOrNil valueForKey:@"result.places"] isKindOfClass:[NSArray class]])
		 
		) {
		
		//	Error #6 means that the location is not in Twitter’s database yet
		
			if ([(NSNumber *)[inUserInfo valueForKey:@"seekAlternativeGeolocationServices"] boolValue] == YES) {
			
				NSLog(@"FIXME: We’re going to ask for help from Google.");
			
			} else {
		
				inFailureCallback(inResponseOrNil, inResponseContext, outNotifyDelegate, outShouldRetry);
				return;
				
			}
		
		}
		
		NSArray *places = [inResponseOrNil valueForKey:@"result.places"];
		
		NSLog(@"geo/reverse_geocode response: %@", inResponseOrNil);
		
	} failureHandler: ^ (NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
	
		inFailureCallback(inResponseOrNil, inResponseContext, outNotifyDelegate, outShouldRetry);
	
	}];

}





@end




