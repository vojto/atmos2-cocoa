/* Copyright (C) 2011 Vojtech Rinik
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

#import <CoreData/CoreData.h>

#import "ATClient.h"
#import "ATObject.h"
#import "NSManagedObject+ATAdditions.h"
#import "ASIHTTPRequest.h"
#import "NSObject+JSON.h"

NSString * const ATObjectEntityName = @"Object";


NSString * const ATMessageVersionKey = @"version";
NSString * const ATMessageATIDKey = @"object_atid";
NSString * const ATMessageObjectKey = @"object";
NSString * const ATMessageObjectDataKey = @"object_data";
NSString * const ATMessageObjectDeletedKey = @"object_deleted";
NSString * const ATMessageObjectRelationsKey = @"object_relations";
NSString * const ATMessageAuthKeyKey = @"auth_key";

// NSString * const ATMessageEntityKey = @"entity";

NSString * const ATDidUpdateObjectNotification = @"ATDidUpdateObjectNotification";

@implementation ATClient

@synthesize metaContext=_metaContext, mappingHelper=_mappingHelper;
@synthesize messageClient=_messageClient, resourceClient=_resourceClient;
@synthesize authKey=_authKey;
@synthesize appContext=_appContext;
@synthesize delegate;

#pragma mark - Lifecycle

- (id) initWithHost:(NSString *)aHost port:(NSInteger)aPort appContext:(NSManagedObjectContext *)context {
    if ((self = [self init])) {
        _needsSync = YES;
        _relationsQueue = [[NSMutableArray alloc] init];
        
        self.metaContext = [[[ATMetaContext alloc] init] autorelease];
        self.appContext = context;
        self.mappingHelper = [[[ATMappingHelper alloc] init] autorelease];
        self.messageClient = [[[ATMessageClient alloc] initWithHost:aHost port:aPort synchronizer:self] autorelease];
        self.resourceClient = [[[ATResourceClient alloc] init] autorelease];
        
        [self _registerForAppNotifications];
        [self.metaContext readVersionFromDefaults];
    }
    return self;
}

- (void) _registerForAppNotifications {
    RKAssert(_appContext, @"App context shouldn't be nil");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didChangeAppObject:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:_appContext];
}

- (void)close {
    [self _saveContext];
    [self _sync];
    [self.messageClient disconnect];
}

#pragma mark Memory Management

- (void) dealloc {
    [_appContext release];
    [_authKey release];
    [_relationsQueue release];
    self.metaContext = nil;
    self.mappingHelper = nil;
    self.messageClient = nil;
    self.resourceClient = nil;
    [super dealloc];
}

#pragma mark - Authentication

- (NSString *)authKeyOrNull {
    return (_authKey ? (id)_authKey : [NSNull null]);
}

#pragma mark - Working with contexts

- (BOOL) _saveContext {
    NSError *error = nil;
    [_context save:&error];
    if (error != nil) {
        ASLogInfo(@"%@", error);
        return NO;
    } else {
        return YES;
    }
}


- (void)applyObjectMessage:(NSDictionary *)content {
    NSString *atID = [content objectForKey:ATMessageATIDKey];
    NSDictionary *data = [content objectForKey:ATMessageObjectDataKey];
    NSNumber *deleted = [content objectForKey:ATMessageObjectDeletedKey];
    NSArray *relations = [content objectForKey:ATMessageObjectRelationsKey];
    NSString *serverEntityName = [content objectForKey:@"object_entity"];
    NSString *localEntityName = [self.mappingHelper localEntityNameFor:serverEntityName];
    NSNumber *versionNumber = [content objectForKey:ATMessageVersionKey];
    NSInteger version = [versionNumber integerValue];
    NSError *error = nil;
    
    ASLogInfo(@"Received push: %@ %@", atID, versionNumber);
    
    ATObject *object = [self _objectWithATID:atID];
    NSManagedObject *appObject;
    if (object && object.isLocked) {
        ASLogInfo(@"Received push for locked object: unlocking, it will sync the next cycle.");
        // At this point we only unlock the object, still marking it as changed
        // so it would sync the next cycle.
        [object unlock];
        [self startSync];
        return;
    } else if (object) {
        appObject = [self _appObjectForObject:object];
        [self _updateAppObject:appObject withData:data relations:relations];
        [_appContext save:&error];
        
    } else {
        appObject = [self _createAppObjectWithLocalEntityName:localEntityName];
        [self _updateAppObject:appObject withData:data relations:relations];
        [_appContext save:&error];
        object = [self _objectForAppObject:appObject];
        object.ATID = atID;
    }
    
    if ([deleted boolValue] == YES) {
        [object markDeleted];
        [self _deleteAppObject:appObject];
    }
    
    if (error != nil) ASLogInfo(@"%@", error);
    [object markSynchronized];
    [object unlock];
    
    if ([self _saveContext]) {
        [self.metaContext updateVersion:version];
        [self _postObjectUpdateNotification:appObject];
    }
}

- (void)_postObjectUpdateNotification:(NSManagedObject *)object {
    NSNotification *notification = [NSNotification notificationWithName:ATDidUpdateObjectNotification object:object];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark - Responding to changes in app objects

- (void) _didChangeAppObject:(NSNotification *)notification {
    ASLogInfo(@"App object just changed. %d", (int)[_appContext hasChanges]);
    NSDictionary *userInfo = [notification userInfo];
    for (NSManagedObject *updatedObject in [userInfo valueForKey:NSUpdatedObjectsKey]) {
        if (![self _attributesChangedInAppObject:updatedObject]) continue;
        [self _markAppObjectChanged:updatedObject];
    }
    NSSet *insertedObjects = [userInfo valueForKey:NSInsertedObjectsKey];
    NSError *error = nil;
    [_appContext obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
    if (error) ASLogInfo(@"Error obtaining permanent IDs: %@", error);
    for (NSManagedObject *insertedObject in insertedObjects) {
//        ATObject *metaObject = [self _objectForAppObject:insertedObject];
        (void)[self _objectForAppObject:insertedObject];
        [self _markAppObjectChanged:insertedObject];
//        [self _saveContext];
    }
    for (NSManagedObject *deletedObject in [userInfo valueForKey:NSDeletedObjectsKey]) {
        [self _markAppObjectDeleted:deletedObject];
    }
    [self startSync];
}

#pragma mark Marking objects

- (void)_markAppObjectChanged:(NSManagedObject *)appObject {    
    ATObject *object = [self _objectForAppObject:appObject];
    
    if ([self _isAppObjectChanged:appObject]) {
        // This happens, when we change object, that's already changed.
        // If something like that happens, it means that we are trying
        // to change an object that hasn't finished syncing yet.
        
        // If we lock an object, the *receive* won't apply the changes,
        // only unlock it, so next sync cycle will send it again with its
        // last changes.
        ASLogInfo(@"Object changed while not synced, locking.");
        [object lock];
        return;
    }
    
    [object markChanged];
}
     
- (void)_markAppObjectSynchronized:(NSManagedObject *)appObject {
    if ([self _isAppObjectChanged:appObject]) {
        return;
    }
    
    ATObject *object = [self _objectForAppObject:appObject];
    
    [object markSynchronized];
}

- (BOOL)_isAppObjectChanged:(NSManagedObject *)appObject {
    ATObject *object = [self _objectForAppObject:appObject];
    
    if ([object.isChanged boolValue]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)_markAppObjectDeleted:(NSManagedObject *)appObject {
    ATObject *object = [self _objectForAppObject:appObject];
    [object markDeleted];
    [object markChanged];
    ASLogInfo(@"Marking app object deleted: %@ (%@)", appObject, object);
}

- (void)addObjectsFromAppContext {
    NSArray *entities = [[[_appContext persistentStoreCoordinator] managedObjectModel] entities];
    for (NSEntityDescription *entity in entities) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        request.entity = entity;
        NSError *error = nil;
        NSArray *result = [_appContext executeFetchRequest:request error:&error];
        if (error) ASLogInfo(@"Error: %@", error);
        for (NSManagedObject *object in result) {
            ASLogInfo(@"Handling object %@ ...", object.objectID);
            ATObject *metaObject = [self _existingMetaObjectForAppObject:object];
            if (!metaObject) {
                ASLogInfo(@"There's no meta object, creating");
                metaObject = [self _objectForAppObject:object];
                [metaObject markChanged];
            }
        }
        [request release];
    }
    [self startSync];
}

#pragma mark - Pushing object to server

- (void)startSync {
    ASLogInfo(@"Scheduling sync for next run loop", nil);
    _needsSync = YES;
    [self performSelectorOnMainThread:@selector(_sync) withObject:nil waitUntilDone:NO];
}

// This will be refactored to use ResourceClient instead of MessageClient, so 
// whatever is in here doesn't matter.
- (void)_sync {
    ASLogError(@"Not implemented yet");
}

- (void) _syncMetaObject:(ATObject *)metaObject {
    ASLogError(@"Not implemented yet");
}

#pragma mark - Managing meta objects

- (ATObject *) _findOrCreateObjectWithID:(NSString *)atID {
    ATObject *object = [self _objectWithATID:atID];
    if (object == nil) object = [self _createObjectWithATID:atID];
    return object;
}

- (ATObject *) _objectWithATID:(NSString *)atID {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ATObjectEntityName];
    request.predicate = [NSPredicate predicateWithFormat:@"ATID = %@", atID];
    request.fetchLimit = 1;
    NSError *error = nil;
    RKAssert(_context, @"Context shouldn't be nil");
    NSArray *results = [_context executeFetchRequest:request error:&error];
    if (error != nil) ASLogInfo(@"Error: %@", error);
    if ([results count] > 0)
        return [results lastObject];
    else
        return nil;
}

- (NSString*) stringWithUUID {
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    [uuidString autorelease];
    return [uuidString lowercaseString];
}

- (ATObject *) _createObjectWithATID:(NSString *)atID {
    ATObject *object = [self _createObject];
    object.ATID = atID;
    return object;
}

- (ATObject *) _createObject {
    ATObject *object = (ATObject *)[NSEntityDescription insertNewObjectForEntityForName:[_objectEntity name] inManagedObjectContext:_context];
    RKAssert(object != nil, @"Created object shouldn't be nil");
    object.ATID = [self stringWithUUID];
    return object;
}

- (ATObject *) _objectForAppObject:(NSManagedObject *)appObject {
    ATObject *object = [self _existingMetaObjectForAppObject:appObject];
    if (!object) {
        object = [self _createObject];
        [object setClientObject:appObject];
    }
    return object;
}

- (ATObject *)_existingMetaObjectForAppObject:(NSManagedObject *)appObject {
    NSError *error = nil;
    NSString *idURIString = [appObject objectIDString];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[_objectEntity name]];
    request.predicate = [NSPredicate predicateWithFormat:@"clientURI = %@", idURIString];
    request.fetchLimit = 1;
    NSArray *objects = [_context executeFetchRequest:request error:&error];
    if (error != nil) ASLogInfo(@"%@", error);
    return [objects lastObject];
}
                                  
#pragma mark - Managing app objects

- (NSManagedObject *) _appObjectForObject:(ATObject *)object {
    return [object clientObjectInContext:_appContext];
}

- (NSManagedObject *) _createAppObjectWithLocalEntityName:(NSString *)localEntityName {
    NSManagedObject *appObject = [NSEntityDescription insertNewObjectForEntityForName:localEntityName inManagedObjectContext:_appContext];
    RKAssert(appObject, @"App object shouldn't be nil");
    return appObject;
}

#pragma mark Updating

- (void) _updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data relations:(NSArray *)relations {
    [self _updateAppObject:appObject withData:data];
    [self _updateAppObject:appObject withRelations:relations];
    [self _applyRelations];
}

- (void)_updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data {
    ASLogInfo(@"Updating object with data");
    for (NSString *key in [data allKeys]) {
        id value = [data objectForKey:key];
        if ([key hasPrefix:@"_"]) continue;
        if (value == [NSNull null]) continue;
        NSString *localAttributeName = [self _localAttributeNameFor:key entity:appObject.entity];
        if (![[appObject.entity propertiesByName] objectForKey:localAttributeName]) {
            ASLogWarning(@"Can't find attribute with name %@", localAttributeName);
            continue;
        }
        [appObject setStringValue:[data objectForKey:key] forKey:localAttributeName];
    }
}

- (void)_updateAppObject:(NSManagedObject *)appObject withRelations:(NSArray *)relations {
    for (NSDictionary *relation in relations)
        [self _enqueueRelation:relation forAppObject:appObject];
}

- (void)_deleteAppObject:(NSManagedObject *)appObject {
    if (appObject != nil) {
        [_appContext deleteObject:appObject];
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
        ATObject *targetMetaObject = [self _objectWithATID:atid];
        if (!targetMetaObject) {
            ASLogWarning(@"Can't find meta object with atid %@ referenced in relation", atid);
            continue;
        }
        NSManagedObject *targetAppObject = [self _appObjectForObject:targetMetaObject];
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
    NSString *entity = [self _serverEntityNameForAppObject:appObject];
    NSArray *attributes = [[appObject entity] attributeKeys];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (NSString *attribute in attributes) {
        NSString *stringValue = [appObject stringValueForKey:attribute];
        NSString *serverAttributeName = [self _serverAttributeNameFor:attribute entity:appObject.entity];
        [data setValue:stringValue forKey:serverAttributeName];
    }
    
    return data;
}

- (NSArray *)_relationsForAppObject:(NSManagedObject *)appObject {
    NSEntityDescription *entityDescription = [appObject entity];
    NSDictionary *relationDescriptions = [entityDescription relationshipsByName];
    ATObject *metaObject = [self _objectForAppObject:appObject];
    NSMutableArray *relations = [NSMutableArray array];
    for (NSString *relationName in [relationDescriptions allKeys]) {
        NSRelationshipDescription *relationDescription = [relationDescriptions objectForKey:relationName];
        NSString *serverRelationName = [self _serverAttributeNameFor:relationName entity:entityDescription];
        if ([relationDescription isToMany]) continue;
        id targetAppObject = [appObject valueForKey:relationName];
        if (!targetAppObject) {
            ASLogInfo(@"Relation is not connected: %@", relationName);
            continue;
        }
        ATObject *targetMetaObject = [self _objectForAppObject:targetAppObject];
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
