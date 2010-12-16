//
//  IRWebAPIInterfaceURLShortening.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 12/16/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"

#ifndef __IRWebAPIInterface__URLShortening__
#define __IRWebAPIInterface__URLShortening__

typedef void (^IRWebAPIInterfaceURLShorteningCallback) (IRWebAPIInterface *inInterface, NSURL *inOriginalURL, NSURL *inShortenedURLOrNil);

#endif





@protocol IRWebAPIInterfaceURLShortening

@required

- (void) shortenURL:(NSURL *)inOriginalURL withCallback:(IRWebAPIInterfaceURLShorteningCallback)inCallback userInfo:(id)inUserInfo;

@end
