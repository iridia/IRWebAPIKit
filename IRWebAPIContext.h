//
//  IRWebAPIContext.h
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/19/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import <Foundation/Foundation.h>





@interface IRWebAPIContext : NSObject {

	NSURL *baseURL;

}

@property (nonatomic, retain, readwrite) NSURL *baseURL;

- (id) initWithBaseURL:(NSURL *)inBaseURL;

- (NSURL *) baseURLForMethodNamed:(NSString *)inMethodName;





@end




