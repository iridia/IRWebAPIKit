//
//  IRWebAPICredentials.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@interface IRWebAPICredentials : NSObject {

	NSString *identifier;
	NSString *identifierPlaceholder;
	
	NSString *qualifier;
	NSString *qualifierPlaceholder;
	
	NSString *displayName;
	NSString *notes;
	
}

@property (nonatomic, readwrite, retain) NSString *identifier;
@property (nonatomic, readwrite, retain) NSString *identifierPlaceholder;
@property (nonatomic, readwrite, retain) NSString *qualifier;
@property (nonatomic, readwrite, retain) NSString *qualifierPlaceholder;
@property (nonatomic, readwrite, retain) NSString *displayName;
@property (nonatomic, readwrite, retain) NSString *notes;
@property (nonatomic, readonly, retain) NSMutableDictionary *userInfo;

@end
