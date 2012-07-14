//
//  ATMetaContext.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <CoreData/NSFetchRequest.h>

#import "RNUtil.h"
#import "ATMetaContext.h"
#import "NSManagedObject+ATAdditions.h"
#import "ATMetaObject.h"

NSString * const ATVersionDefaultsKey = @"ATVersion";
NSString * const ATObjectEntityName = @"Object";


@interface ATMetaContext ()

@property (retain) NSMutableDictionary *_objects;

@end

@implementation ATMetaContext

@synthesize _objects;

/*****************************************************************************/
#pragma mark - Lifecycle
/*****************************************************************************/

+ (id)restore {
    ATMetaContext *instance = [NSKeyedUnarchiver unarchiveObjectWithFile:[self path]];
    if (!instance) {
        instance = [[[ATMetaContext alloc] init] autorelease];
    }

    return instance;
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<ATMetaContext _objects=%@>", [self._objects description]];
}

/*****************************************************************************/
#pragma mark - Saving
/*****************************************************************************/

- (BOOL)save {
    ASLogDebug(@"Queuing save");
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_saveImmediately) withObject:nil afterDelay:0.1];
    return YES;
}

- (void)_saveImmediately {
    ASLogInfo(@"Saving meta context");
    [NSKeyedArchiver archiveRootObject:self toFile:[self.class path]];
}


/*****************************************************************************/
#pragma mark Marking objects
/*****************************************************************************/

- (void)markURIChanged:(ATObjectURI *)uri {
    ATMetaObject *object = [self ensureObjectAtURI:uri];
    object.isChanged = YES;
}

- (void)markURISynced:(ATObjectURI *)uri {
    ATMetaObject *object = [self ensureObjectAtURI:uri];
    object.isChanged = NO;
    object.isLocalOnly = NO;
}

- (void)markURIDeleted:(ATObjectURI *)uri {
    ATMetaObject *object = [self ensureObjectAtURI:uri]; // TODO: Really wanna ensure?
    object.isChanged = YES;
    object.isDeleted = YES;
}

- (ATMetaObject *)ensureObjectAtURI:(ATObjectURI *)uri {
    ATMetaObject *object = [self objectAtURI:uri];
    if (!object) object = [self createObjectAtURI:uri];
    return object;
}

- (ATMetaObject *)objectAtURI:(ATObjectURI *)uri {
    NSString *key = [uri stringValue];
    return [self._objects objectForKey:key];
}

- (ATMetaObject *)createObjectAtURI:(ATObjectURI *)uri {
    NSString *key = [uri stringValue];
    ATMetaObject *object = [[[ATMetaObject alloc] initWithURI:uri] autorelease];
    [self._objects setObject:object forKey:key];
    return object;
}

/*****************************************************************************/
#pragma mark - Finding objects
/*****************************************************************************/

- (NSArray *)allObjects {
    return [self._objects allValues];
}

- (NSArray *)changedObjects {
    NSMutableArray *objects = [NSMutableArray array];
    for (ATMetaObject *object in self.allObjects) {
        if (object.isChanged == YES) [objects addObject:object];
    }
    return objects;
}

/*****************************************************************************/
#pragma mark - Other tasks
/*****************************************************************************/

- (void)changeIDTo:(NSString *)newID atURI:(ATObjectURI *)uri {
    ATMetaObject *object = [self objectAtURI:uri];
    ATObjectURI *newURI = [uri copy];
    newURI.identifier = newID;
    object.uri = newURI;
    [self._objects setObject:object forKey:[newURI stringValue]];
    [self._objects removeObjectForKey:[uri stringValue]];
}

- (void)deleteObjectAtURI:(ATObjectURI *)uri {
    NSString *key = [uri stringValue];
    [self._objects removeObjectForKey:key];
}


@end
