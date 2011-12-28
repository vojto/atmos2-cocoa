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

@synthesize managedContext=_managedContext;

#pragma mark - Saving

- (BOOL)save {
    NSError *error = nil;
    [self.managedContext save:&error];
    if (error != nil) {
        ASLogInfo(@"%@", error);
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Managing version number

- (void)readVersionFromDefaults {
    _version = [(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:ATVersionDefaultsKey] intValue];
}

- (void)writeVersionToDefaults {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:_version] forKey:ATVersionDefaultsKey];
}

- (void)updateVersion:(NSInteger)version
{
    if (version > _version) {
        _version = version;
        [self writeVersionToDefaults];
    }
}

- (NSNumber *)versionAsNumber {
    return [NSNumber numberWithLong:_version];
}

#pragma mark - Managing meta objects

- (ATObject *)findOrCreateObjectWithID:(NSString *)atID {
    ATObject *object = [self objectWithATID:atID];
    if (object == nil) object = [self createObjectWithATID:atID];
    return object;
}

- (ATObject *)objectWithATID:(NSString *)atID {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ATObjectEntityName];
    request.predicate = [NSPredicate predicateWithFormat:@"ATID = %@", atID];
    request.fetchLimit = 1;
    NSError *error = nil;
    RKAssert(self.managedContext, @"Context shouldn't be nil");
    NSArray *results = [self.managedContext executeFetchRequest:request error:&error];
    if (error != nil) ASLogInfo(@"Error: %@", error);
    if ([results count] > 0)
        return [results lastObject];
    else
        return nil;
}

- (NSString*)stringWithUUID {
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    [uuidString autorelease];
    return [uuidString lowercaseString];
}

- (ATObject *)createObjectWithATID:(NSString *)atID {
    ATObject *object = [self createObject];
    object.ATID = atID;
    return object;
}

- (ATObject *)createObject {
    ATObject *object = (ATObject *)[NSEntityDescription insertNewObjectForEntityForName:[_objectEntity name] inManagedObjectContext:self.managedContext];
    RKAssert(object != nil, @"Created object shouldn't be nil");
    object.ATID = [self stringWithUUID];
    return object;
}

- (ATObject *)objectForAppObject:(NSManagedObject *)appObject {
    ATObject *object = [self existingMetaObjectForAppObject:appObject];
    if (!object) {
        object = [self createObject];
        [object setClientObject:appObject];
    }
    return object;
}

- (ATObject *)existingMetaObjectForAppObject:(NSManagedObject *)appObject {
    NSError *error = nil;
    NSString *idURIString = [appObject objectIDString];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[_objectEntity name]];
    request.predicate = [NSPredicate predicateWithFormat:@"clientURI = %@", idURIString];
    request.fetchLimit = 1;
    NSArray *objects = [self.managedContext executeFetchRequest:request error:&error];
    if (error != nil) ASLogInfo(@"%@", error);
    return [objects lastObject];
}

@end
