//
//  ATAppContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ATObject.h"
#import "ATAttributeMapper.h"
#import "ATSynchronizer.h"
#import "ATObjectURI.h"

@interface ATAppContext : NSObject {
    ATSynchronizer *_sync;
    
    NSManagedObjectContext *_managedContext;
    NSMutableArray *_relationsQueue;
}

@property (assign) ATSynchronizer *sync;
@property (assign) NSManagedObjectContext *managedContext;
@property (retain) ATAttributeMapper *attributeMapper;

#pragma mark - Lifecycle
+ (id)sharedAppContext;
- (id)initWithSynchronizer:(ATSynchronizer *)aSync appContext:(NSManagedObjectContext *)anAppContext;

#pragma mark - Managing app objects using URI
- (NSManagedObject *)appObjectAtURI:(ATObjectURI)uri;
- (NSManagedObject *)createAppObjectAtURI:(ATObjectURI)uri;
- (Class)_managedClassForURI:(ATObjectURI)uri;
- (ATObjectURI)URIOfAppObject:(NSManagedObject *)object;

#pragma mark - Updating
- (void)updateAppObject:(NSManagedObject *)appObject withDictionary:(NSDictionary *)data;
- (void)deleteAppObject:(NSManagedObject *)appObject;

#pragma mark - Resolving relations
- (void)_resolveRelations:(NSManagedObject *)appObject withDictionary:(NSDictionary *)data;

#pragma mark Serializing
- (NSDictionary *)dataForAppObject:(NSManagedObject *)appObject;
- (NSArray *)relationsForAppObject:(NSManagedObject *)appObject;

#pragma mark - Checking attribute changes
- (BOOL)attributesChangedInAppObject:(NSManagedObject *)appObject;

#pragma mark - Core Data
- (BOOL)hasChanges;
- (void)save:(NSError **)error;
- (void)obtainPermanentIDsForObjects:(NSArray *)objects error:(NSError **)error;

@end
