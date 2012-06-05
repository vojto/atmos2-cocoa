//
//  ATAppContext.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ASLogger.h"
#import "RNUtil.h"

#import "ATSynchronizer.h"
#import "ATAppContext.h"
#import "NSManagedObject+ATAdditions.h"

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

- (void)save {
    NSError *error = nil;
    [self save:&error];
    if (error != nil) {
        ASLogError(@"[ATAppContext] Save failed: %@", error);
    }
}

- (void)save:(NSError **)error {
    [self.managedContext save:error];
}

- (void)obtainPermanentIDsForObjects:(NSArray *)objects error:(NSError **)error {
    [self.managedContext obtainPermanentIDsForObjects:objects error:error];
}

#pragma mark - Managing App Objects

- (NSManagedObject *)objectAtURI:(ATObjectURI *)uri {
    Class managedClass = [self _managedClassForURI:uri];
    NSManagedObject *managedObject = [managedClass MR_findFirstByAttribute:@"identifier" withValue:uri.identifier];

    return managedObject;
}

- (NSManagedObject *)createAppObjectAtURI:(ATObjectURI *)uri {
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:uri.entity inManagedObjectContext:self.managedContext];
    [object setValue:uri.identifier forKey:@"identifier"];
    // TODO: Apply attributes (we might create a helper object for this, something like
    
    // ATAttributeMapper
    return object;
}

- (Class)_managedClassForURI:(ATObjectURI *)uri {
    NSEntityDescription *entity = [NSEntityDescription entityForName:uri.entity inManagedObjectContext:self.managedContext];
    NSString *className = [entity managedObjectClassName];
    RKAssert(className, @"Entity %@ has no class", uri.entity);
    Class managedClass = NSClassFromString(className);
    NSEntityDescription *backReferenceToEntity = [managedClass MR_entityDescriptionInContext:self.managedContext];
    RKAssert(backReferenceToEntity, @"Entity class for %@ doesn't return back reference (use entityName, entityInManagedObjectContext:)", entity.name);
    NSPropertyDescription *identifier = [[entity propertiesByName] objectForKey:@"identifier"];
    RKAssert(identifier, @"Entity %@ doesn't have an identifier field. This is required to store primary keys of remote objects.", entity.name);
    return managedClass;
}

- (ATObjectURI *)URIOfAppObject:(NSManagedObject *)object {
    NSLog(@"Getting URI of %@", object);
    return [ATObjectURI URIWithEntity:object.entity.name identifier:[object valueForKey:@"identifier"]];
}

- (void)changeIDTo:(NSString *)newID atURI:(ATObjectURI *)uri {
    NSManagedObject *object = [self objectAtURI:uri];
    [object setValue:newID forKey:@"identifier"];
    // TODO: Consider saving here
    // [self save];
}

#pragma mark Updating

- (void)updateAppObject:(NSManagedObject *)appObject withDictionary:(NSDictionary *)data {
    ASLogInfo(@"Updating object with data %@", data);
    // TODO: Go through attributes in map instead of in incoming dictionary
    for (NSString *key in [data allKeys]) {
        id value = [data objectForKey:key];
        if ([key hasPrefix:@"_"]) continue;
        if ([key isEqualToString:@"identifier"]) continue;
        if (value == [NSNull null]) continue;
        NSString *localAttributeName = [self.sync.mappingHelper localAttributeNameFor:key entity:appObject.entity];
        if (![[appObject.entity propertiesByName] objectForKey:localAttributeName]) {
            // ASLogWarning(@"Can't find attribute with name %@", localAttributeName);
            continue;
        }
        [appObject setStringValue:[data objectForKey:key] forKey:localAttributeName];
    }
    
    [self _resolveRelations:appObject withDictionary:data];
    
    [self save];
}

- (void)deleteAppObject:(NSManagedObject *)appObject {
    if (appObject != nil) {
        [self.managedContext deleteObject:appObject];
    }
}

#pragma mark - Resolving relations

- (void)_resolveRelations:(NSManagedObject *)appObject withDictionary:(NSDictionary *)data {
    ATMappingHelper     *mapping    = self.sync.mappingHelper;
    NSEntityDescription *entity     = appObject.entity;
    NSDictionary        *relations  = entity.relationshipsByName;
    
    for (NSString *relation in relations.allKeys) {
        NSRelationshipDescription *description = [relations objectForKey:relation];
        NSEntityDescription *destinationDescription = description.destinationEntity;
        NSString *serverRelationName = [mapping serverRelationNameFor:relation entity:entity];

        if ([description isToMany]) continue;

        NSString *value = [data objectForKey:serverRelationName];
        if (!value) continue;

        NSString *destinationEntity = destinationDescription.name;
        ATObjectURI *targetURI = [ATObjectURI URIWithEntity:destinationEntity identifier:value];

        NSManagedObject *targetObject = [self objectAtURI:targetURI];
        if (!targetObject) {
            ASLogWarning(@"Target object %@/%@ referenced in relation %@ of %@ not found", targetURI.entity, targetURI.identifier, relation, entity.name);
            continue;
        }
        [appObject setValue:targetObject forKey:relation];
    }
}



#pragma mark Serializing

- (NSDictionary *)dataForObject:(NSManagedObject *)object {
    ATMappingHelper     *mapping    = self.sync.mappingHelper;
    NSEntityDescription *entity     = object.entity;
    NSMutableDictionary *data       = [NSMutableDictionary dictionary];
    NSDictionary        *relations  = entity.relationshipsByName;
    
    // Add attributes
    NSArray *attributes = entity.attributesByName.allKeys;
    for (NSString *attribute in attributes) {
        NSString *stringValue = [object stringValueForKey:attribute];
        NSString *serverAttributeName = [mapping serverAttributeNameFor:attribute entity:object.entity];
        [data setValue:stringValue forKey:serverAttributeName];
    }
    
    // Add relations    
    for (NSString *relation in relations.allKeys) {
        NSRelationshipDescription *description = [relations objectForKey:relation];
        NSString *serverRelationName = [mapping serverRelationNameFor:relation entity:entity];
        if ([description isToMany]) continue;
        id target = [object valueForKey:relation];
        if (!target) {
            ASLogWarning(@"Relation is not connected: %@", relation);
            continue;
        }
        NSString *identifier = [target valueForKey:@"identifier"];
        if (!identifier) {
            ASLogError(@"Relation target doens't have an identifier: %@", target);
            continue;
        }
        // TODO: What if the object doesn't have an identifier yet?
        [data setObject:identifier forKey:serverRelationName];
    }
    
    return data;
}

- (NSArray *)_relationsForAppObject:(NSManagedObject *)appObject {
    ATMappingHelper *mapping = self.sync.mappingHelper;
    NSEntityDescription *entityDescription = [appObject entity];
    NSDictionary *relationDescriptions = [entityDescription relationshipsByName];
//    ATObject *metaObject = [self.sync.metaContext objectForAppObject:appObject];
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
//        ATObject *targetMetaObject = [self.sync.metaContext objectForAppObject:targetAppObject];
//        if (!targetMetaObject) {
//            ASLogWarning(@"Couldn't find meta object for object %@ referenced in relation", targetAppObject);
//            continue;
//        }
//        NSDictionary *relation = [NSMutableDictionary dictionaryWithObjectsAndKeys:serverRelationName, @"name", [metaObject ATID], @"source", [targetMetaObject ATID], @"target", nil];
        
//        [relations addObject:relation];
    }
    
    return relations;
}

#pragma mark - Checking attribute changes

- (BOOL)attributesChangedInAppObject:(NSManagedObject *)appObject {
    NSDictionary *changedValues = [appObject changedValuesForCurrentEvent];
    NSArray *changedKeys = [changedValues allKeys];
    NSArray *attributeNames = [[[appObject entity] attributesByName] allKeys]; // TODO: Check if attributeKeys works
    for (NSString *attributeName in attributeNames) {
        if ([attributeName isEqualToString:@"identifier"]) continue; // TODO: Use constant not string
        if ([changedKeys containsObject:attributeName]) return YES;
    }
    return NO;
}

@end
