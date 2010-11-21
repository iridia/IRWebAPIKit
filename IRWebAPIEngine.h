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
	
	NSMutableArray *globalRequestPreTransformers;
	NSMutableDictionary *requestTransformers;
	NSMutableArray *globalRequestPostTransformers;

	NSMutableArray *globalResponsePreTransformers;
	NSMutableDictionary *responseTransformers;
	NSMutableArray *globalResponsePostTransformers;
	
	dispatch_queue_t sharedDispatchQueue;

}

@property (nonatomic, readwrite, retain) IRWebAPIResponseParser parser;
@property (nonatomic, readonly, retain) IRWebAPIContext *context;

@property (nonatomic, retain, readonly) NSMutableArray *globalRequestPreTransformers;
@property (nonatomic, retain, readonly) NSMutableDictionary *requestTransformers;
@property (nonatomic, retain, readonly) NSMutableArray *globalRequestPostTransformers;

@property (nonatomic, retain, readonly) NSMutableArray *globalResponsePreTransformers;
@property (nonatomic, retain, readonly) NSMutableDictionary *responseTransformers;
@property (nonatomic, retain, readonly) NSMutableArray *globalResponsePostTransformers;





- (id) initWithContext:(IRWebAPIContext *)inContext;
	
- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler;

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil options:(NSDictionary *)inOptionsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler;

- (NSMutableArray *) requestTransformersForMethodNamed:(NSString *)inMethodName;
- (NSMutableArray *) responseTransformersForMethodNamed:(NSString *)inMethodName;





@end




