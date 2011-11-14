//
//  IRWebAPIEngine+ExternalTransforms.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/14/11.
//  Copyright (c) 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIEngine.h"


@interface IRWebAPIEngine (ExternalTransforms)

- (NSURLRequest *) transformedRequestWithRequest:(NSURLRequest *)aRequest usingMethodName:(NSString *)aName;

//	Infers a context object from the request, punts it thru the global pre transformers, method-specific ones if any, then the global post transformers, and finally configures a new request with the transformed context object.

@end
