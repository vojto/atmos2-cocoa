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
#import "WebSocket.h"

NSString * const ATVersionDefaultsKey = @"ATVersion";

NSString * const ATConnectClientMessage = @"client-connect";

NSString * const ATObjectEntityName = @"Object";

NSString * const ATMessageServerPushType = @"server-push";
NSString * const ATMessageClientPushType = @"client-push";
NSString * const ATMessageServerAuthFailureType = @"server-auth-failure";
NSString * const ATMessageServerAuthSuccessType = @"server-auth-success";

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

@synthesize appContext=_appContext;
@synthesize entitiesMap=_entitiesMap, attributesMap=_attributesMap;
@synthesize delegate;

#pragma mark - Lifecycle

- (id) initWithURL:(NSString *)aURL appContext:(NSManagedObjectContext *)context {
    if ((self = [self init])) {
        _URL = [aURL copy];
        [self _readVersionFromDefaults];
        _context = [self _createContext];
        self.appContext = context;
        [self _registerForAppNotifications];
        _needsSync = YES;
        _relationsQueue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSManagedObjectContext *)_createContext {
    NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] init] autorelease];
    _objectEntity = [[[NSEntityDescription alloc] init] autorelease];
    _objectEntity.name = ATObjectEntityName;
    _objectEntity.managedObjectClassName = @"ATObject";
    NSAttributeDescription *clientURI = [[[NSAttributeDescription alloc] init] autorelease];
    clientURI.name = @"clientURI";
    [clientURI setAttributeType:NSStringAttributeType];
    [clientURI setOptional:NO];
    NSAttributeDescription *atID = [[[NSAttributeDescription alloc] init] autorelease];
    atID.name = @"ATID";
    atID.attributeType = NSStringAttributeType;
    [atID setOptional:YES];
    
    NSAttributeDescription *isChanged = [[[NSAttributeDescription alloc] init] autorelease];
    isChanged.name = @"isChanged";
    [isChanged setAttributeType:NSBooleanAttributeType];
    [isChanged setDefaultValue:[NSNumber numberWithBool:NO]];
    [isChanged setOptional:YES];
    
    NSAttributeDescription *isMarkedDeleted = [[[NSAttributeDescription alloc] init] autorelease];
    isMarkedDeleted.name = @"isMarkedDeleted";
    [isMarkedDeleted setAttributeType:NSBooleanAttributeType];
    [isMarkedDeleted setDefaultValue:[NSNumber numberWithBool:NO]];
    [isMarkedDeleted setOptional:YES];
    
    NSArray *properties = [NSArray arrayWithObjects:clientURI, atID, isChanged, isMarkedDeleted, nil];
    [_objectEntity setProperties:properties];
    [model setEntities:[NSArray arrayWithObjects:_objectEntity, nil]];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    [context setPersistentStoreCoordinator:coordinator];
    NSArray *libURLs = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSURL *libURL = [libURLs lastObject];
    libURL = [libURL URLByAppendingPathComponent:executableName];
    [[NSFileManager defaultManager] createDirectoryAtURL:libURL withIntermediateDirectories:YES attributes:nil error:nil];
    NSURL *storeURL = [libURL URLByAppendingPathComponent:@"Atmosphere.xml"];
    ASLogInfo(@"Store URL: %@", storeURL);
    NSPersistentStore *store = [coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:storeURL options:nil error:nil];
    ASLogInfo(@"Store: %@", store);
    
    return context;
}

- (void) _registerForAppNotifications {
    RKAssert(_appContext, @"App context shouldn't be nil");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didChangeAppObject:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:_appContext];
}

- (void) _readVersionFromDefaults {
    _version = [(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:ATVersionDefaultsKey] intValue];
}

- (void) _writeVersionToDefaults {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:_version] forKey:ATVersionDefaultsKey];
}

- (void) _updateVersion:(NSInteger)version
{
    if (version > _version) {
        _version = version;
        [self _writeVersionToDefaults];
    }
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

#pragma mark - Mapping

- (NSString *) _localEntityNameFor:(NSString *)serverEntityName {
    NSString *name = [_entitiesMap objectForKey:serverEntityName];
    return name ? name : serverEntityName;
}

- (NSString *) _serverEntityNameFor:(NSString *)localEntityName {
    for (NSString *serverName in [_entitiesMap allKeys]) {
        if ([localEntityName isEqualToString:[self _localEntityNameFor:serverName]]) {
            return serverName;
        }
    }
    return localEntityName;
}

- (NSString *)_serverEntityNameForAppObject:(NSManagedObject *)appObject {
    NSEntityDescription *entityDescription = [appObject entity];
    return [self _serverEntityNameFor:[entityDescription name]];
}

- (NSString *)_serverAttributeNameFor:(NSString *)localName entity:(NSEntityDescription *)entity {
    NSDictionary *map = [_attributesMap objectForKey:entity.name];
    
    for (NSString *serverName in [map allKeys]) {
        NSString *someLocalName = [map objectForKey:serverName];
        if ([someLocalName isEqualToString:localName])
            return serverName;
    }
    
    return localName;
}

- (NSString *)_localAttributeNameFor:(NSString *)serverName entity:(NSEntityDescription *)entity {
    NSDictionary *map = [_attributesMap objectForKey:entity.name];
    NSString *localName = [map objectForKey:serverName];
    if (localName) {
        return localName;
    } else {
        return serverName;
    }
}

#pragma mark - Connecting

- (void) connect {
    _isRunning = YES;
    [self _initializeSocketConnection];
}

- (void)connectWithKey:(NSString *)key {
    _authKey = [key copy];
    [self connect];
}

- (BOOL)isConnected {
    return [_connection isConnected];
}

- (void) _initializeSocketConnection {
    [_connection disconnect];
    [_connection autorelease];
    ASLogInfo(@"Connecting to host: %@", _URL);
    NSString *url = [_URL stringByReplacingOccurrencesOfString:@"ws:" withString:@""];
    url = [url stringByReplacingOccurrencesOfString:@"wss:" withString:@""];
    url = [url stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSArray *components = [url componentsSeparatedByString:@":"];
    NSString *hostname = [components objectAtIndex:0];
    NSString *port = [components objectAtIndex:1];
    
    _connection = [[SocketIO alloc] initWithDelegate:self];
    [_connection connectToHost:hostname onPort:[port integerValue]];
}

- (void)socketIODidConnect:(SocketIO *)socket {
    ASLogInfo(@"Web Socket connection opened");
    [self _sendConnectMessage];
    [self _startSync];
}

- (void) _sendConnectMessage {
    // Send the "Connect Client" message
    ATMessage *connectMessage = [[ATMessage alloc] init];
    connectMessage.type = ATConnectClientMessage;
    connectMessage.content = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithLong:_version], ATMessageVersionKey,
                              (_authKey ? (id)_authKey : [NSNull null]), ATMessageAuthKeyKey,
                              nil];
    ASLogInfo(@"Sending connect message with version %d and auth key %@", (int)_version, _authKey);
    [self sendMessage:connectMessage];
    
    // [connectMessage release];
}

#pragma mark - Disconnecting

- (void)disconnect {
    _isRunning = NO;
    [self _saveContext];
    [self _sync];
    [_connection close];
}

- (void)webSocketDidClose:(WebSocket *)webSocket {
    if (_isRunning) {
//        ASLogInfo(@"Disconnected, reconnecting...");
//        [self performSelector:@selector(connect) withObject:nil afterDelay:5];
    }
}

#pragma mark - Posting notifications
//
- (void)_postObjectUpdateNotification:(NSManagedObject *)object {
    NSNotification *notification = [NSNotification notificationWithName:ATDidUpdateObjectNotification object:object];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark - Messaging

- (void)sendMessage:(ATMessage *)message {
    [_connection sendMessage:[message JSONString]];
}

- (void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    ATMessage *message = [ATMessage messageFromJSONString:packet.data];
    NSString *type = message.type;
    ASLogInfo(@"Received message: %@", type);
    NSDictionary *content = message.content;
    if ([type isEqualToString:ATMessageServerPushType]) {
        [self _didReceiveServerPush:content];
    } else if ([type isEqualToString:ATMessageServerAuthFailureType]) {
        [self _didReceiveServerAuthFailure:content];
    } else if ([type isEqualToString:ATMessageServerAuthSuccessType]) {
        [self _didReceiveServerAuthSuccess:content];
    }
}

#pragma mark Handling server push

- (void) _didReceiveServerPush:(NSDictionary *)content {
    NSString *atID = [content objectForKey:ATMessageATIDKey];
    NSDictionary *data = [content objectForKey:ATMessageObjectDataKey];
    NSNumber *deleted = [content objectForKey:ATMessageObjectDeletedKey];
    NSArray *relations = [content objectForKey:ATMessageObjectRelationsKey];
    NSString *serverEntityName = [content objectForKey:@"object_entity"];
    NSString *localEntityName = [self _localEntityNameFor:serverEntityName];
    NSNumber *versionNumber = [content objectForKey:ATMessageVersionKey];
    NSInteger version = [versionNumber integerValue];
    NSError *error = nil;
    
//    ASLogInfo(@"Received push: %@", content);
    ASLogInfo(@"Received push: %@ %@", atID, versionNumber);

    ATObject *object = [self _objectWithATID:atID];
    NSManagedObject *appObject;
    if (object && object.isLocked) {
        ASLogInfo(@"Received push for locked object: unlocking, it will sync the next cycle.");
        // At this point we only unlock the object, still marking it as changed
        // so it would sync the next cycle.
        [object unlock];
        [self _startSync];
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
        [self _updateVersion:version];
        [self _postObjectUpdateNotification:appObject];
    }
}

#pragma mark Responding to authentication messages

- (void)_didReceiveServerAuthSuccess:(NSDictionary *)data {
    [delegate clientAuthDidSucceed:self];
    [self _startSync];
}

- (void)_didReceiveServerAuthFailure:(NSDictionary *)data {
    [delegate clientAuthDidFail:self];
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
    [self _startSync];
}

#pragma mark Marking objects
- (void) _markAppObjectChanged:(NSManagedObject *)appObject {    
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
     
- (void) _markAppObjectSynchronized:(NSManagedObject *)appObject {
    if ([self _isAppObjectChanged:appObject]) {
        return;
    }
    
    ATObject *object = [self _objectForAppObject:appObject];
    
    [object markSynchronized];
}

- (BOOL) _isAppObjectChanged:(NSManagedObject *)appObject {
    ATObject *object = [self _objectForAppObject:appObject];
    
    if ([object.isChanged boolValue]) {
        return YES;
    } else {
        return NO;
    }
}

- (void) _markAppObjectDeleted:(NSManagedObject *)appObject {
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
    [self _startSync];
}

#pragma mark - Pushing object to server

- (void) _startSync {
    ASLogInfo(@"Scheduling sync for next run loop", nil);
    _needsSync = YES;
    [self performSelectorOnMainThread:@selector(_sync) withObject:nil waitUntilDone:NO];
}

- (void) _sync {
    if (!_needsSync)
        return;
    
    ASLogInfo(@"Syncing");

    if (![self isConnected]) {
        ASLogInfo(@"Not syncing because we're not connceted");
        return;
    }
    
    [self _saveContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ATObjectEntityName];
    request.predicate = [NSPredicate predicateWithFormat:@"isChanged = YES"];
    NSError *error = nil;
    NSArray *results = [_context executeFetchRequest:request error:&error];

    for (ATObject *metaObject in results) {
        if ([metaObject isLocked]) {
            ASLogInfo(@"Skipping object because it's locked: %@", metaObject.objectID);
            continue;
        }
        ASLogInfo(@"Syncing object: %@", metaObject.ATID);
        [self _syncMetaObject:metaObject];
    }
    
    _needsSync = NO;
}

- (void) _syncMetaObject:(ATObject *)metaObject {
    ATMessage *message = [[ATMessage alloc] init];
    message.type = ATMessageClientPushType;
    
    id atID = metaObject.ATID ? metaObject.ATID : (id)[NSNull null];
    NSDictionary *content, *object;
    if ([metaObject.isMarkedDeleted boolValue]) {
        ASLogInfo(@"Object is deleted: ", metaObject);
        NSNumber *deleted = [NSNumber numberWithBool:YES];
        object = [NSDictionary dictionaryWithObjectsAndKeys:deleted, @"deleted", nil];
    } else {
        NSManagedObject *appObject = [self _appObjectForObject:metaObject];
        if (!appObject) {
            ASLogInfo(@"App object not found, meta object is not marked as deleted, %@", metaObject);
            return;
        }
        id entity, data, relations, deleted;
        entity = [self _serverEntityNameForAppObject:appObject];
        data = [self _dataForAppObject:appObject];
        relations = [self _relationsForAppObject:appObject];
        deleted = [NSNumber numberWithBool:NO];
        
        object = [NSDictionary dictionaryWithObjectsAndKeys:entity, @"entity", 
                  data, @"data",
                  relations, @"relations", nil];
        [data release];
    }
    
    content = [NSDictionary dictionaryWithObjectsAndKeys:object, ATMessageObjectKey, 
               atID, ATMessageATIDKey, nil];

    message.content = content;
    [self sendMessage:message];
    [message release];
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

#pragma mark - Memory Management

- (void) dealloc {
    [_connection release];
    [_URL release];
    [_appContext release];
    [_authKey release];
    [_relationsQueue release];
    [super dealloc];
}

@end
