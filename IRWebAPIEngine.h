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

//	endpoint
//	methods
//	authenticator

	CFMutableDictionaryRef successHandlers;
	CFMutableDictionaryRef failureHandlers;

}

@property (nonatomic, readonly, retain) IRWebAPIContext *context;

- (id) initWithContext:(IRWebAPIContext *)inContext;

//	@property (nonatomic, retain, readwrite) NSMutableArray *globalRequestTransformers;
//	@property (nonatomic, retain, readwrite) NSMutableDictionary *requestTransformers;
//	@property (nonatomic, assign, readwrite) id delegate;

- (void) fireAPIRequestNamed:(NSString *)inMethodName withArguments:(NSDictionary *)inArgumentsOrNil onSuccess:(IRWebAPICallback)inSuccessHandler onFailure:(IRWebAPICallback)inFailureHandler;

@end


