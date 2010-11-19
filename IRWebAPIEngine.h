//
//  IRWebAPIEngine.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRWebAPIKit.h"





@interface IRWebAPIEngine : NSObject {

	IRWebAPIResponseParser parser;

	CFMutableDictionaryRef successHandlers;
	CFMutableDictionaryRef failureHandlers;
	CFMutableDictionaryRef dataStore;
	
	NSMutableArray *globalRequestTransformers;
	NSMutableDictionary *requestTransformers;

	NSMutableArray *globalResponseTransformers;
	NSMutableDictionary *responseTransformers;

}

@property (nonatomic, readwrite, retain) IRWebAPIResponseParser parser;
@property (nonatomic, readonly, retain) IRWebAPIContext *context;

@property (nonatomic, retain, readonly) NSMutableArray *globalRequestTransformers;
@property (nonatomic, retain, readonly) NSMutableDictionary *requestTransformers;

@property (nonatomic, retain, readonly) NSMutableArray *globalResponseTransformers;
@property (nonatomic, retain, readonly) NSMutableDictionary *responseTransformers;





- (id) initWithContext:(IRWebAPIContext *)inContext;
	
- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler;





@end




