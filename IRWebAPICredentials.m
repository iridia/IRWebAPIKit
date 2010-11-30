//
//  IRWebAPICredentials.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPICredentials.h"


@implementation IRWebAPICredentials

@synthesize identifier, identifierPlaceholder, identifierLabelText, qualifier, qualifierPlaceholder, qualifierLabelText, displayName, notes, userInfo;

- (id) init {

	self = [super init]; if (!self) return nil;
	
	identifier = nil;
	identifierPlaceholder = nil;
	qualifier = nil;
	qualifierPlaceholder = nil;
	displayName = nil;
	notes = nil;
	userInfo = [[NSMutableDictionary dictionary] retain];
	
	return self;

}

- (id) initWithIdentifier:(NSString *)inIdentifier qualifier:(NSString *)inQualifier {

	self = [self init]; if (!self) return nil;
	
	self.identifier = inIdentifier;
	self.qualifier = inQualifier;
	
	return self;

}

- (void) dealloc {

	[identifier release];
	[identifierPlaceholder release];
	
	[qualifier release];
	[qualifierPlaceholder release];
	
	[displayName release];
	[notes release];
	[userInfo release];
	
	[super dealloc];

}

- (id) initWithCoder:(NSCoder *)inCoder {

	self = [self init]; if (!self) return nil;
	
	identifier = [inCoder decodeObjectForKey:@"identifier"];
	identifierPlaceholder = [inCoder decodeObjectForKey:@"identifierPlaceholder"];
	qualifier = [inCoder decodeObjectForKey:@"qualifier"];
	qualifierPlaceholder = [inCoder decodeObjectForKey:@"qualifierPlaceholder"];
	displayName = [inCoder decodeObjectForKey:@"displayName"];
	notes = [inCoder decodeObjectForKey:@"notes"];
	userInfo = [inCoder decodeObjectForKey:@"userInfo"];
	
	return self;

}

- (void) encodeWithCoder:(NSCoder *)inCoder {

	[inCoder encodeObject:identifier forKey:@"identifier"];
	[inCoder encodeObject:identifierPlaceholder forKey:@"identifierPlaceholder"];
	[inCoder encodeObject:qualifier forKey:@"qualifier"];
	[inCoder encodeObject:qualifierPlaceholder forKey:@"qualifierPlaceholder"];
	[inCoder encodeObject:displayName forKey:@"displayName"];
	[inCoder encodeObject:notes forKey:@"notes"];
	[inCoder encodeObject:userInfo forKey:@"userInfo"];

}

@end
