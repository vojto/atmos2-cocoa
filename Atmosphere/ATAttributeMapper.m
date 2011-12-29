//
//  ATAttributeMapper.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATAttributeMapper.h"
#import "NSManagedObject+ATAdditions.h"

@implementation ATAttributeMapper

@synthesize mappingHelper = _mappingHelper;

#pragma mark - Lifecycle

- (id)initWithMappingHelper:(ATMappingHelper *)mappingHelper {
    self = [super init];
    if (self) {
        self.mappingHelper = mappingHelper;
    }
    
    return self;
}


@end
