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

@interface ATMetaContext ()

@property (retain) NSMutableDictionary *_data;

@end

@implementation ATMetaContext

@synthesize _data;

#pragma mark - Lifecycle

- (id)init {
    if ((self = [super init])) {
        self._data = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - Saving

- (BOOL)save {
    
}

#pragma mark Marking objects

- (void)markURIChanged:(ATObjectURI)uri {
    
}

@end
