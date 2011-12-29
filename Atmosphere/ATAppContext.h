//
//  ATAppContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ATObject.h"

@class ATSynchronizer;

typedef struct _ATObjectURI {
    NSString *entity;
    NSString *identifier;
} ATObjectURI;

ATObjectURI ATObjectURIMake(NSString *entity, NSString *identifier);

@interface ATAppContext : NSObject {
    ATSynchronizer *_sync;
    
    NSManagedObjectContext *_managedContext;
    NSMutableArray *_relationsQueue;
}

@property (assign) ATSynchronizer *sync;
@property (assign) NSManagedObjectContext *managedContext;

#pragma mark - Lifecycle
+ (id)sharedAppContext;
- (id)initWithSynchronizer:(ATSynchronizer *)aSync appContext:(NSManagedObjectContext *)anAppContext;

#pragma mark - Managing app objects using URI
- (NSManagedObject *)appObjectAtURI:(ATObjectURI)uri;
- (NSManagedObject *)createAppObjectAtURI:(ATObjectURI)uri;
- (Class)_managedClassForURI:(ATObjectURI)uri;

#pragma mark - Managing app objects
- (NSManagedObject *)appObjectForObject:(ATObject *)object;
- (NSManagedObject *)createAppObjectWithLocalEntityName:(NSString *)localEntityName;

#pragma mark - Updating
- (void)updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data relations:(NSArray *)relations;
- (void)updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data;
- (void)updateAppObject:(NSManagedObject *)appObject withRelations:(NSArray *)relations;
- (void)deleteAppObject:(NSManagedObject *)appObject;

#pragma mark - Relations queue
- (void)_enqueueRelation:(NSDictionary *)relation forAppObject:(NSManagedObject *)appObject;
- (void)_applyRelations;

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
