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


/***************** META OBJECT **********************************************************/

@interface ATMetaObject : NSObject <NSCoding> {
@private
    
}

@property ATObjectURI uri;
@property BOOL isChanged;
@property BOOL isLocalOnly;

- (id)initWithURI:(ATObjectURI)uri;

@end

@implementation ATMetaObject

@synthesize uri, isChanged, isLocalOnly;

- (id)initWithURI:(ATObjectURI)aURI {
    if ((self = [super init])) {
        self.uri = aURI;
        self.isChanged = YES;
        self.isLocalOnly = YES;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.uri = ATObjectURIFromString([decoder decodeObjectForKey:@"uri"]);
        [self.uri.entity retain];
        [self.uri.identifier retain];
        self.isChanged = [[decoder decodeObjectForKey:@"isChanged"] boolValue];
        self.isLocalOnly = [[decoder decodeObjectForKey:@"isLocalOnly"] boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:ATObjectURIToString(self.uri) forKey:@"uri"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isChanged] forKey:@"isChanged"];
    [encoder encodeObject:[NSNumber numberWithBool:self.isLocalOnly] forKey:@"isLocalOnly"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<ATMetaObject uri=%@, isChanged=%d, isLocalOnly=%d", ATObjectURIToString(self.uri), self.isChanged, self.isLocalOnly];
}

@end

/***************** META OBJECT **********************************************************/


@interface ATMetaContext ()

@property (retain) NSMutableDictionary *_objects;

@end

@implementation ATMetaContext

@synthesize _objects;

#pragma mark - Lifecycle

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

#pragma mark - Saving

- (BOOL)save {
    NSLog(@"Archiving: %@", [self.class path]);
    [NSKeyedArchiver archiveRootObject:self toFile:[self.class path]];
    return YES;
}

#pragma mark Marking objects

- (void)markURIChanged:(ATObjectURI)uri {
    ATMetaObject *object = [self ensureObjectAtURI:uri];
    object.isChanged = YES;
    [self save];
}

- (ATMetaObject *)ensureObjectAtURI:(ATObjectURI)uri {
    ATMetaObject *object = [self objectAtURI:uri];
    if (!object) object = [self createObjectAtURI:uri];
    return object;
}

- (ATMetaObject *)objectAtURI:(ATObjectURI)uri {
    NSString *key = ATObjectURIToString(uri);
    return [self._objects objectForKey:key];
}

- (ATMetaObject *)createObjectAtURI:(ATObjectURI)uri {
    NSString *key = ATObjectURIToString(uri);
    ATMetaObject *object = [[[ATMetaObject alloc] initWithURI:uri] autorelease];
    [self._objects setObject:object forKey:key];
    return object;
}

#pragma mark - Finding objects

- (NSArray *)changedObjects {
    NSMutableArray *objects = [NSMutableArray array];
    [[self._objects allKeys] enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        ATMetaObject *object = [self._objects objectForKey:key];
        if (object.isChanged == YES) {
            [objects addObject:object];
        }
    }];
    return objects;
}

@end
