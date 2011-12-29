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
@synthesize attributeMapper=_attributeMapper;

#pragma mark - Lifecycle

+ (id)sharedAppContext {
    return _sharedAppContext;
}

- (id)initWithSynchronizer:(ATSynchronizer *)aSync appContext:(NSManagedObjectContext *)anAppContext {
    if ((self = [super init])) {
        self.sync = aSync;
        self.managedContext = anAppContext;
        self.attributeMapper = [[[ATAttributeMapper alloc] initWithMappingHelper:self.sync.mappingHelper] autorelease];
        
        _relationsQueue = [[NSMutableArray alloc] init];
        
        _sharedAppContext = self;
    }
    return self;
}

- (void)dealloc {
    [_relationsQueue release];
    self.attributeMapper = nil;
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
    Class managedClass = [self _managedClassForURI:uri];
    NSManagedObject *managedObject = [managedClass findFirstByAttribute:@"identifier" withValue:uri.identifier];

    return managedObject;
}

- (NSManagedObject *)createAppObjectAtURI:(ATObjectURI)uri {
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:uri.entity inManagedObjectContext:self.managedContext];
    [object setValue:uri.identifier forKey:@"identifier"];
    // TODO: Apply attributes (we might create a helper object for this, something like
    
    // ATAttributeMapper
    return object;
}

- (Class)_managedClassForURI:(ATObjectURI)uri {
    NSEntityDescription *entity = [NSEntityDescription entityForName:uri.entity inManagedObjectContext:self.managedContext];
    NSString *className = [entity managedObjectClassName];
    RKAssert(className, @"Entity %@ has no class", uri.entity);
    Class managedClass = NSClassFromString(className);
    NSEntityDescription *backReferenceToEntity = [managedClass entityDescriptionInContext:self.managedContext];
    RKAssert(backReferenceToEntity, @"Entity class for %@ doesn't return back reference (use entityName, entityInManagedObjectContext:)", entity.name);
    NSPropertyDescription *identifier = [[entity propertiesByName] objectForKey:@"identifier"];
    RKAssert(identifier, @"Entity %@ doesn't have an identifier field. This is required to store primary keys of remote objects.", entity.name);
    return managedClass;
}

#pragma mark Updating

- (void)updateAppObject:(NSManagedObject *)appObject withDictionary:(NSDictionary *)data {
    ASLogInfo(@"Updating object with data");
    // TODO: Go through attributes in map instead of in incoming dictionary
    for (NSString *key in [data allKeys]) {
        id value = [data objectForKey:key];
        if ([key hasPrefix:@"_"]) continue;
        if (value == [NSNull null]) continue;
        NSString *localAttributeName = [self.sync.mappingHelper localAttributeNameFor:key entity:appObject.entity];
        if (![[appObject.entity propertiesByName] objectForKey:localAttributeName]) {
            // ASLogWarning(@"Can't find attribute with name %@", localAttributeName);
            continue;
        }
        [appObject setStringValue:[data objectForKey:key] forKey:localAttributeName];
    }
    
    [self _resolveRelations:appObject withDictionary:data];
    
    NSError *error = nil;
    [self save:&error];
    if (error) ASLogError(@"%@", error);
}

- (void)deleteAppObject:(NSManagedObject *)appObject {
    if (appObject != nil) {
        [self.managedContext deleteObject:appObject];
    }
}

#pragma mark - Resolving relations

- (void)_resolveRelations:(NSManagedObject *)appObject withDictionary:(NSDictionary *)data {
    // "relation"    is remote
    // "association" is local
    NSEntityDescription *entity = appObject.entity;
    NSDictionary *relations = [self.sync.mappingHelper relationsForEntity:entity];
    ASLogInfo(@"Resolving %d relations for entity %@", [relations count], entity.name);
    for (NSString *key in [relations allKeys]) {
        NSString *name = [relations objectForKey:key];
        NSRelationshipDescription *relation = [[entity relationshipsByName] objectForKey:name];
        RKAssert(relation, @"No relation %@ found for entity", name, entity);
        NSString *targetId = [data objectForKey:key];
        if (!targetId) {
            ASLogWarning(@"Relation %@ not found in data %@", key, data);
            continue;
        }
        // Find the target
        NSString *targetEntityName = relation.destinationEntity.name;
        ATObjectURI targetURI = ATObjectURIMake(targetEntityName , targetId);
        NSManagedObject *targetObject = [self appObjectAtURI:targetURI];
        if (!targetObject) {
            ASLogWarning(@"Target object %@/%@ referenced in relation %@ of %@ not found", targetURI.entity, targetURI.identifier, key, entity.name);
            continue;
        }
        // Make the connection
        [appObject setValue:targetObject forKey:name];
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
