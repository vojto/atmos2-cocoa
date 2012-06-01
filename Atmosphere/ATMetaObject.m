//
//  ATMetaObject.m
//  Atmosphere
//
//  Created by Rinik Vojto on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ATMetaObject.h"

NSString * const kATMetaObjectIsChangedKey = @"isChanged";
NSString * const kATMetaObjectIsLocalOnlyKey = @"isLocalOnly";
NSString * const kATMetaObjectIsDeletedKey = @"isDeleted";

@implementation ATMetaObject

@synthesize uri, isChanged, isLocalOnly, isDeleted;

- (id)initWithURI:(ATObjectURI *)aURI {
    if ((self = [super init])) {
        self.uri = aURI;
        self.isChanged = YES;
        self.isLocalOnly = YES;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.uri = [ATObjectURI URIFromString:[decoder decodeObjectForKey:@"uri"]];
        [self.uri.entity retain];
        [self.uri.identifier retain];
        self.isChanged = [[decoder decodeObjectForKey:kATMetaObjectIsChangedKey] boolValue];
        self.isLocalOnly = [[decoder decodeObjectForKey:kATMetaObjectIsLocalOnlyKey] boolValue];
        self.isDeleted = [[decoder decodeObjectForKey:kATMetaObjectIsDeletedKey] boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:[self.uri stringValue] forKey:@"uri"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isChanged] forKey:kATMetaObjectIsChangedKey];
    [encoder encodeObject:[NSNumber numberWithBool:self.isLocalOnly] forKey:kATMetaObjectIsLocalOnlyKey];
    [encoder encodeObject:[NSNumber numberWithBool:self.isDeleted] forKey:kATMetaObjectIsDeletedKey];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<ATMetaObject uri=%@, isChanged=%d, isLocalOnly=%d, isDeleted=%d", [uri stringValue], self.isChanged, self.isLocalOnly, self.isDeleted];
}

@end