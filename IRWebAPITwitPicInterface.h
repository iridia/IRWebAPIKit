//
//  IRWebAPITwitPicInterface.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 1/24/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@interface IRWebAPITwitPicInterface : IRWebAPIInterface <IRWebAPIImageStorageProvider, IRWebAPIInterfaceOAuthEchoReliance>

@property (nonatomic, readwrite, retain) NSString *apiKey;

@end
