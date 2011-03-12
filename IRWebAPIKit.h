//
//  IRWebAPIKit.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//





#if 0

	#define IRWebAPIKitLog( s, ... ) NSLog( @"<%s : (%d)> %@",__FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#else

	#define IRWebAPIKitLog( s, ... ) 

#endif





#import "IRWebAPIKitDefines.h"

#import "IRWebAPIResponseParser.h"
#import "IRWebAPIKitEntityDefines.h"
#import "IRWebAPIHelpers.h"

#import "IRWebAPIEngine.h"
#import "IRWebAPIContext.h"
#import "IRWebAPIAuthenticator.h"
#import "IRWebAPICredentials.h"
#import "IRWebAPIInterface.h"

#import "IRWebAPIInterfaceAuthenticating.h"
#import "IRWebAPIInterfaceXOAuthAuthenticating.h"
#import "IRWebAPIInterfaceOAuthEchoReliance.h"

#import "IRWebAPIInterfaceURLShortening.h"

#import "IRWebAPIGoogleReaderAuthenticator.h"
#import "IRWebAPIXOAuthAuthenticator.h"

#import "IRWebAPITwitterInterface.h"
#import "IRWebAPIGoogleReaderInterface.h"

#import "IRWebAPIImageStorageProvider.h"
#import "IRWebAPITwitPicInterface.h"

#import "IRRemoteResourcesManager.h"





