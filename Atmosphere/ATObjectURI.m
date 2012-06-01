//
//  ATObjectURI.m
//  Atmosphere
//
//  Created by Rinik Vojto on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RNUtil.h"

#import "ATObjectURI.h"

@implementation ATObjectURI

@synthesize entity = _entity, identifier = _identifier;

+ (id)URIWithEntity:(NSString *)entity identifier:(NSString *)identifier {
    return [[[ATObjectURI alloc] initWithEntity:entity identifier:identifier] autorelease];
}

- (id)initWithEntity:(NSString *)entity identifier:(NSString *)identifier {
    if ((self = [super init])) {
        self.entity = entity;
        self.identifier = identifier;
    }
    
    return self;
}

+ (id)URIFromString:(NSString *)string {
    return [[[ATObjectURI alloc] initFromString:string] autorelease];
}

- (id)initFromString:(NSString *)string {
    NSArray *comps = [string componentsSeparatedByString:@"."];
    RKAssert(([comps count] == 2), @"Expected URI to have to components separated by '.'");
    
    NSString *entity = [comps objectAtIndex:0];
    NSString *identifier = [comps objectAtIndex:1];
    
    return [self initWithEntity:entity identifier:identifier];
}

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"%@.%@", self.entity, self.identifier];
}

@end