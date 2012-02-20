//
//  ATMetaContext.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreData/NSFetchRequest.h>
#import "ATMetaContext.h"
#import "NSManagedObject+ATAdditions.h"

NSString * const ATVersionDefaultsKey = @"ATVersion";
NSString * const ATObjectEntityName = @"Object";

@implementation ATMetaContext

#pragma mark - Lifecycle

- (id)init {
    if ((self = [super init])) {
        
    }
    
    return self;
}

#pragma mark - Saving

- (BOOL)save {
    
}

#pragma mark Marking objects


@end
