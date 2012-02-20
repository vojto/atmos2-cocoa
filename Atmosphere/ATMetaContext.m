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

@property (retain) NSMutableDictionary *_objects;

@end

@implementation ATMetaContext

@synthesize _objects;

#pragma mark - Lifecycle

+ (id)restore {
    ATMetaContext *instance = [NSKeyedUnarchiver unarchiveObjectWithFile:[self path]];
    if (!instance) {
        instance = [[ATMetaContext alloc] init];
    }

    return [instance autorelease];
}

- (id)init {
    if ((self = [super init])) {
        self._objects = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (NSString *)path {
    NSString *support = [RNUtil applicationSupportDirectory];
    NSString *path = [support stringByAppendingPathComponent:@"ATMetaContext.plist"];
    return path;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self._objects = [decoder decodeObjectForKey:@"objects"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self._objects forKey:@"objects"];
}

#pragma mark - Saving

- (BOOL)save {
    NSLog(@"ARchiving: %@", [self.class path]);
    [NSKeyedArchiver archiveRootObject:self toFile:[self.class path]];
    return YES;
}

#pragma mark Marking objects



@end
