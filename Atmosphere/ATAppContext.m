//
//  ATAppContext.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ATSynchronizer.h"
#import "ATAppContext.h"
#import "ATObject.h"
#import "NSManagedObject+ATActiveRecord.h"
#import "NSManagedObject+ATAdditions.h"

ATObjectURI ATObjectURIMake(NSString *entity, NSString *identifier) {
    ATObjectURI uri;
    uri.entity = entity;
    uri.identifier = identifier;
    return uri;
}

static ATAppContext* _sharedAppContext = nil;

@implementation ATAppContext

@synthesize sync=_sync;
@synthesize managedContext=_managedContext;

#pragma mark - Lifecycle

+ (id)sharedAppContext {
    return _sharedAppContext;
}

- (id)initWithSynchronizer:(ATSynchronizer *)aSync appContext:(NSManagedObjectContext *)anAppContext {
    if ((self = [super init])) {
        self.sync = aSync;
        self.managedContext = anAppContext;
        
        _relationsQueue = [[NSMutableArray alloc] init];
        
        _sharedAppContext = self;
    }
    return self;
}

- (void)dealloc {
    [_relationsQueue release];
    [super dealloc];
}

#pragma mark - Core Data

- (BOOL)hasChanges {
    return [self.managedContext hasChanges];
}

- (void)save:(NSError **)error {
    [self.managedContext save:error];
}

- (void)obtainPermanentIDsForObjects:(NSArray *)objects error:(NSError **)error {
    [self.managedContext obtainPermanentIDsForObjects:objects error:error];
}

#pragma mark - Managing App Objects

- (NSManagedObject *)appObjectAtURI:(ATObjectURI)uri {
    NSEntityDescription *entity = [NSEntityDescription entityForName:uri.entity inManagedObjectContext:self.managedContext];
    NSString *className = [entity managedObjectClassName];
    RKAssert(className, @"Entity %@ has no class", uri.entity);
    Class managedClass = NSClassFromString(className);
    NSManagedObject *managedObject = [managedClass findFirstByAttribute:@"identifier" withValue:uri.identifier];
    NSLog(@"Managed object: %@", managedObject);
    return nil;
}

- (NSManagedObject *)appObjectForObject:(ATObject *)object {
    return [object clientObjectInContext:self.managedContext];
}

- (NSManagedObject *)createAppObjectWithLocalEntityName:(NSString *)localEntityName {
    NSManagedObject *appObject = [NSEntityDescription insertNewObjectForEntityForName:localEntityName inManagedObjectContext:self.managedContext];
    RKAssert(appObject, @"App object shouldn't be nil");
    return appObject;
}

#pragma mark Updating

- (void)updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data relations:(NSArray *)relations {
    [self updateAppObject:appObject withData:data];
    [self updateAppObject:appObject withRelations:relations];
    [self _applyRelations];
}

- (void)updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data {
    ASLogInfo(@"Updating object with data");
    for (NSString *key in [data allKeys]) {
        id value = [data objectForKey:key];
        if ([key hasPrefix:@"_"]) continue;
        if (value == [NSNull null]) continue;
        NSString *localAttributeName = [self.sync.mappingHelper localAttributeNameFor:key entity:appObject.entity];
        if (![[appObject.entity propertiesByName] objectForKey:localAttributeName]) {
            ASLogWarning(@"Can't find attribute with name %@", localAttributeName);
            continue;
        }
        [appObject setStringValue:[data objectForKey:key] forKey:localAttributeName];
    }
}

- (void)updateAppObject:(NSManagedObject *)appObject withRelations:(NSArray *)relations {
    for (NSDictionary *relation in relations)
        [self _enqueueRelation:relation forAppObject:appObject];
}

- (void)deleteAppObject:(NSManagedObject *)appObject {
    if (appObject != nil) {
        [self.managedContext deleteObject:appObject];
    }
}

#pragma mark - Relations queue

- (void) _enqueueRelation:(NSDictionary *)relation forAppObject:(NSManagedObject *)appObject {
    NSDictionary *relationDescription =
    [NSDictionary dictionaryWithObjectsAndKeys:appObject, @"appObject",
     relation, @"relation", nil];
    [_relationsQueue addObject:relationDescription];
}

- (void) _applyRelations {
    ASLogInfo(@"Applying %d relations", [_relationsQueue count]);
    NSMutableArray *trash = [NSMutableArray array];
    for (NSDictionary *relationDescription in _relationsQueue) {
        NSDictionary *relation = [relationDescription objectForKey:@"relation"];
        NSManagedObject *appObject = [relationDescription objectForKey:@"appObject"];
        NSString *name = [relation objectForKey:@"name"];
        // Use this to find target entity. Don't forget to translate it using the entity map.
        // NSString *targetEntity = [relation objectForKey:@"target_entity"]; 
        NSString *atid = [relation objectForKey:@"target"];
        ATObject *targetMetaObject = [self.sync.metaContext objectWithATID:atid];
        if (!targetMetaObject) {
            ASLogWarning(@"Can't find meta object with atid %@ referenced in relation", atid);
            continue;
        }
        NSManagedObject *targetAppObject = [self appObjectForObject:targetMetaObject];
        if (!targetAppObject) {
            ASLogWarning(@"Can't find app object with atid %@ referenced in relation", atid);
            continue;
        }
        [appObject setValue:targetAppObject forKey:name];
        [trash addObject:relationDescription];
    }
    for (id relation in trash) {
        [_relationsQueue removeObject:relation];
    }
}

#pragma mark Serializing

- (NSDictionary *) _dataForAppObject:(NSManagedObject *)appObject {
    ATMappingHelper *mapping = self.sync.mappingHelper;
    // NSString *entity = [mapping serverEntityNameForAppObject:appObject];
    NSArray *attributes = [[appObject entity] attributeKeys];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (NSString *attribute in attributes) {
        NSString *stringValue = [appObject stringValueForKey:attribute];
        NSString *serverAttributeName = [mapping serverAttributeNameFor:attribute entity:appObject.entity];
        [data setValue:stringValue forKey:serverAttributeName];
    }
    
    return data;
}

- (NSArray *)_relationsForAppObject:(NSManagedObject *)appObject {
    ATMappingHelper *mapping = self.sync.mappingHelper;
    NSEntityDescription *entityDescription = [appObject entity];
    NSDictionary *relationDescriptions = [entityDescription relationshipsByName];
    ATObject *metaObject = [self.sync.metaContext objectForAppObject:appObject];
    NSMutableArray *relations = [NSMutableArray array];
    for (NSString *relationName in [relationDescriptions allKeys]) {
        NSRelationshipDescription *relationDescription = [relationDescriptions objectForKey:relationName];
        NSString *serverRelationName = [mapping serverAttributeNameFor:relationName entity:entityDescription];
        if ([relationDescription isToMany]) continue;
        id targetAppObject = [appObject valueForKey:relationName];
        if (!targetAppObject) {
            ASLogInfo(@"Relation is not connected: %@", relationName);
            continue;
        }
        ATObject *targetMetaObject = [self.sync.metaContext objectForAppObject:targetAppObject];
        if (!targetMetaObject) {
            ASLogWarning(@"Couldn't find meta object for object %@ referenced in relation", targetAppObject);
            continue;
        }
        NSDictionary *relation = [NSMutableDictionary dictionaryWithObjectsAndKeys:serverRelationName, @"name", [metaObject ATID], @"source", [targetMetaObject ATID], @"target", nil];
        
        [relations addObject:relation];
    }
    
    return relations;
}

#pragma mark - Checking attribute changes

- (BOOL)_attributesChangedInAppObject:(NSManagedObject *)appObject {
    NSDictionary *changedValues = [appObject changedValuesForCurrentEvent];
    NSArray *changedKeys = [changedValues allKeys];
    NSArray *attributeNames = [[[appObject entity] attributesByName] allKeys]; // TODO: Check if attributeKeys works
    for (NSString *attributeName in attributeNames) {
        if ([changedKeys containsObject:attributeName]) return YES;
    }
    return NO;
}

@end
