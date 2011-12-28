//
//  ATMetaContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATObject.h"

@interface ATMetaContext : NSObject {
    NSInteger _version;
    NSManagedObjectContext *_managedContext;
    NSEntityDescription *_objectEntity;
}

@property (nonatomic, retain) NSManagedObjectContext *managedContext;

#pragma mark - Saving
- (BOOL)save;

#pragma mark - Managing version number
- (void)readVersionFromDefaults;
- (void)writeVersionToDefaults;
- (void)updateVersion:(NSInteger)version;
- (NSNumber *)versionAsNumber;

#pragma mark - Managing local objects
// - (ATObject *) _findOrCreateObjectWithATID:(NSString *)atID;
- (ATObject *)objectWithATID:(NSString *)atID;
- (ATObject *)createObjectWithATID:(NSString *)atID;
- (ATObject *)createObject;
- (ATObject *)objectForAppObject:(NSManagedObject *)appObject;
- (ATObject *)existingMetaObjectForAppObject:(NSManagedObject *)appObject;

@end
