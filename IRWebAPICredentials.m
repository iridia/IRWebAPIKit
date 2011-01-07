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
	
	self.identifier = nil;
	self.identifierPlaceholder = nil;
	self.identifierLabelText = nil;
	self.qualifier = nil;
	self.qualifierPlaceholder = nil;
	self.qualifierLabelText = nil;
	self.displayName = nil;
	self.notes = nil;
	self.userInfo = [[NSMutableDictionary dictionary] retain];
	self.authenticated = NO;
	
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
	[identifierLabelText release];
	
	[qualifier release];
	[qualifierPlaceholder release];
	[qualifierLabelText release];
	
	[displayName release];
	[notes release];
	[userInfo release];
	
	[super dealloc];

}

- (id) initWithCoder:(NSCoder *)inCoder {

	self = [self init]; if (!self) return nil;
	
	self.identifier = [inCoder decodeObjectForKey:@"identifier"];
	self.identifierPlaceholder = [inCoder decodeObjectForKey:@"identifierPlaceholder"];
	self.identifierLabelText = [inCoder decodeObjectForKey:@"identifierLabelText"];
	self.qualifier = [inCoder decodeObjectForKey:@"qualifier"];
	self.qualifierPlaceholder = [inCoder decodeObjectForKey:@"qualifierPlaceholder"];
	self.qualifierLabelText = [inCoder decodeObjectForKey:@"qualifierLabelText"];
	self.displayName = [inCoder decodeObjectForKey:@"displayName"];
	self.notes = [inCoder decodeObjectForKey:@"notes"];
	self.userInfo = [inCoder decodeObjectForKey:@"userInfo"];
	self.authenticated = [(NSNumber *)[inCoder decodeObjectForKey:@"authenticated"] boolValue];
	
	return self;

}

- (void) encodeWithCoder:(NSCoder *)inCoder {

	[inCoder encodeObject:identifier forKey:@"identifier"];
	[inCoder encodeObject:identifierPlaceholder forKey:@"identifierPlaceholder"];
	[inCoder encodeObject:identifierLabelText forKey:@"identifierLabelText"];
	[inCoder encodeObject:qualifier forKey:@"qualifier"];
	[inCoder encodeObject:qualifierPlaceholder forKey:@"qualifierPlaceholder"];
	[inCoder encodeObject:qualifierLabelText forKey:@"qualifierLabelText"];
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
	copy.identifierLabelText = self.identifierLabelText;
	copy.qualifier = self.qualifier;
	copy.qualifierPlaceholder = self.qualifierPlaceholder;
	copy.qualifierLabelText = self.qualifierLabelText;
	copy.displayName = self.displayName;
	copy.notes = self.notes;
	copy.userInfo = [[self.userInfo copy] autorelease];
	copy.authenticated = self.authenticated;

	return copy;

}

- (NSString *) description {

	id (^wrap)(id) = ^ id (id obj) {
	
		return obj ? (id)obj : (id)@"(null)";
	
	};
	
	return [[NSDictionary dictionaryWithObjectsAndKeys:
	
		wrap(self.identifier), @"identifier",
		wrap(self.identifierPlaceholder), @"identifierPlaceholder",
		wrap(self.identifierLabelText), @"identifierLabelText",
		wrap(self.qualifier), @"qualifier",
		wrap(self.qualifierPlaceholder), @"qualifierPlaceholder",
		wrap(self.qualifierLabelText), @"qualifierLabelText",
		wrap(self.displayName), @"displayName",
		wrap(self.notes), @"notes",
		wrap(self.userInfo), @"userInfo",
		[NSNumber numberWithBool:self.authenticated], @"authenticated",
	
	nil] description];

}

@end
