//
//  IRWebAPICredentials.m
//  IRWebAPIKit
//
//  Created by Evadne Wu on 11/21/10.
//  Copyright 2010 Iridia Productions. All rights reserved.
//

#import "IRWebAPICredentials.h"


@implementation IRWebAPICredentials

@synthesize identifier, identifierPlaceholder, identifierLabelText, qualifier, qualifierPlaceholder, qualifierLabelText, displayName, notes, userInfo, authenticated;

- (id) init {

	self = [super init]; if (!self) return nil;
	
	identifier = nil;
	identifierPlaceholder = nil;
	qualifier = nil;
	qualifierPlaceholder = nil;
	displayName = nil;
	notes = nil;
	userInfo = [[NSMutableDictionary dictionary] retain];
	authenticated = NO;
	
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
	authenticated = [(NSNumber *)[inCoder decodeObjectForKey:@"authenticated"] boolValue];
	
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
	[inCoder encodeObject:[NSNumber numberWithBool:authenticated] forKey:@"authenticated"];

}

- (id)copyWithZone:(NSZone *)zone {

	return self;

//	Although copying sounds good, it breaks our hash in an authentication manager

	IRWebAPICredentials *copy = [[[self class] allocWithZone: zone] init];
	
	copy.identifier = self.identifier;
	copy.identifierPlaceholder = self.identifierPlaceholder;
	copy.qualifier = self.qualifier;
	copy.qualifierPlaceholder = self.qualifierPlaceholder;
	copy.displayName = self.displayName;
	copy.notes = self.notes;
	copy.userInfo = [[self.userInfo copy] autorelease];
	copy.authenticated = self.authenticated;

	return copy;

}

- (NSString *) description {

	return [[NSDictionary dictionaryWithObjectsAndKeys:
	
		self.identifier, @"identifier",
		self.identifierPlaceholder, @"identifierPlaceholder",
		self.qualifier, @"qualifier",
		self.qualifierPlaceholder, @"qualifierPlaceholder",
		self.displayName, @"displayName",
		self.notes, @"notes",
		self.userInfo, @"userInfo",
		[NSNumber numberWithBool:self.authenticated], @"authenticated",
	
	nil] description];

}

@end
