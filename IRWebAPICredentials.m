//
//  IRWebAPICredentials.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPICredentials.h"


@implementation IRWebAPICredentials

@synthesize identifier, identifierPlaceholder, qualifier, qualifierPlaceholder, displayName, notes;

- (id) init {

	self = [super init]; if (!self) return nil;
	
	identifier = nil;
	identifierPlaceholder = nil;
	qualifier = nil;
	qualifierPlaceholder = nil;
	displayName = nil;
	notes = nil;
	
	return self;

}

- (id) initWithCoder:(NSCoder *)inCoder {

	self = [self init]; if (!self) return nil;
	
	identifier = [inCoder decodeObjectForKey:@"identifier"];
	identifierPlaceholder = [inCoder decodeObjectForKey:@"identifierPlaceholder"];
	qualifier = [inCoder decodeObjectForKey:@"qualifier"];
	qualifierPlaceholder = [inCoder decodeObjectForKey:@"qualifierPlaceholder"];
	displayName = [inCoder decodeObjectForKey:@"displayName"];
	notes = [inCoder decodeObjectForKey:@"notes"];
	
	return self;

}

- (void) encodeWithCoder:(NSCoder *)inCoder {

	[inCoder encodeObject:identifier forKey:@"identifier"];
	[inCoder encodeObject:identifierPlaceholder forKey:@"identifierPlaceholder"];
	[inCoder encodeObject:qualifier forKey:@"qualifier"];
	[inCoder encodeObject:qualifierPlaceholder forKey:@"qualifierPlaceholder"];
	[inCoder encodeObject:displayName forKey:@"displayName"];
	[inCoder encodeObject:notes forKey:@"notes"];

}

@end
