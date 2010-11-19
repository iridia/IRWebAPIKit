//
//  IRWebAPIResponseParser.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/20/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IRWebAPIKit.h"

#ifndef IRWebAPIResponseParserSections
#define IRWebAPIResponseParserSections





static inline IRWebAPIResponseParser IRWebAPIResponseDefaultParserMake () {

	NSDictionary * (^defaultParser) (NSData *) = ^ NSDictionary * (NSData *inData) {
	
		return [NSDictionary dictionaryWithObject:inData forKey:@"response"];
	
	};

	return defaultParser;

}





#endif




