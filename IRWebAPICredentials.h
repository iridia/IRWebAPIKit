//
//  IRWebAPICredentials.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPIKit.h"


@interface IRWebAPICredentials : NSObject <NSCopying, NSCoding> {

}

@property (nonatomic, readwrite, retain) NSString *identifier;
@property (nonatomic, readwrite, retain) NSString *identifierPlaceholder;
@property (nonatomic, readwrite, retain) NSString *identifierLabelText;

@property (nonatomic, readwrite, retain) NSString *qualifier;
@property (nonatomic, readwrite, retain) NSString *qualifierPlaceholder;
@property (nonatomic, readwrite, retain) NSString *qualifierLabelText;

@property (nonatomic, readwrite, retain) NSString *displayName;
@property (nonatomic, readwrite, retain) NSString *notes;
@property (nonatomic, readwrite, retain) NSMutableDictionary *userInfo;

@property (nonatomic, readwrite, assign) BOOL authenticated;

- (id) initWithIdentifier:(NSString *)inIdentifier qualifier:(NSString *)inQualifier;

@end
