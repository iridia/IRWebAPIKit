//
//  IRWebAPIKit.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>





@class IRWebAPIEngine;
@class IRWebAPIContext;





typedef NSDictionary * (^IRWebAPITransformer) (NSDictionary *inOriginalContent);

typedef void (^IRWebAPICallback) (IRWebAPIEngine *inEngine, NSDictionary *inResponseOrNil, BOOL *inNotifyDelegate, BOOL *inShouldRetry);





#import "IRWebAPIEngine.h"
#import "IRWebAPIContext.h"




