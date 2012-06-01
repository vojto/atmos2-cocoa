//
//  ATMetaObject.m
//  Atmosphere
//
//  Created by Rinik Vojto on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ATMetaObject.h"

@implementation ATMetaObject

@synthesize uri, isChanged, isLocalOnly;

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
        self.isChanged = [[decoder decodeObjectForKey:@"isChanged"] boolValue];
        self.isLocalOnly = [[decoder decodeObjectForKey:@"isLocalOnly"] boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:[self.uri stringValue] forKey:@"uri"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isChanged] forKey:@"isChanged"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isLocalOnly] forKey:@"isLocalOnly"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<ATMetaObject uri=%@, isChanged=%d, isLocalOnly=%d", [uri stringValue], self.isChanged, self.isLocalOnly];
}

@end