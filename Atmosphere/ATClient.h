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

#import "SocketIO.h"
#import "ATMessage.h"
#import "ATObject.h"

extern NSString * const ATDidUpdateObjectNotification;

@class ATClient;

@protocol ATClientDelegate <NSObject>

- (void) clientAuthDidSucceed:(ATClient *)client;
- (void) clientAuthDidFail:(ATClient *)client;

@end

@interface ATClient : NSObject <SocketIODelegate> {
   
    /** App */
    NSManagedObjectContext *_appContext;
    NSDictionary *_entitiesMap;
    NSDictionary *_attributesMap;
    
    /** State */
    BOOL _isRunning;
    NSInteger _version;
    NSString *_authKey;
    BOOL _needsSync;
    NSMutableArray *_relationsQueue;
    
    /** Schema */
    NSManagedObjectContext *_context;
    NSEntityDescription *_objectEntity;
    
    
    /** Connection */
    NSString *_host;
    NSInteger _port;
    SocketIO *_connection;
    
    /** Delegate */
    id<ATClientDelegate> delegate;
}

/** Application managed object context. Atmosphere client won't
 work without setting this property. */
@property (nonatomic, assign) NSManagedObjectContext *appContext;
/** Entities map dictionary. Key represents server entity name
 and value represents client entity name */
@property (nonatomic, retain) NSDictionary *entitiesMap;
@property (nonatomic, retain) NSDictionary *attributesMap;
@property (assign) id<ATClientDelegate> delegate;

#pragma mark - Lifecycle
- (id) initWithHost:(NSString *)aHost port:(NSInteger)aPort appContext:(NSManagedObjectContext *)context;
- (NSManagedObjectContext *) _createContext;
- (void)_registerForAppNotifications;

#pragma mark - Connecting
- (void) connect;
- (void) connectWithKey:(NSString *)key;
- (BOOL)isConnected;
#pragma mark Auth
- (void)_didReceiveServerAuthFailure:(NSDictionary *)data;
- (void)_didReceiveServerAuthSuccess:(NSDictionary *)data;

#pragma mark - Managing version number
- (void) _readVersionFromDefaults;
- (void) _writeVersionToDefaults;
- (void) _updateVersion:(NSInteger)version;

#pragma mark - Working with contexts
- (BOOL) _saveContext;

#pragma mark - Mapping
- (NSString *) _localEntityNameFor:(NSString *)serverEntityName;
- (NSString *) _serverEntityNameFor:(NSString *)localEntityName;
- (NSString *) _serverEntityNameForAppObject:(NSManagedObject *)appObject;
- (NSString *)_serverAttributeNameFor:(NSString *)localName entity:(NSEntityDescription *)entity;
- (NSString *)_localAttributeNameFor:(NSString *)serverName entity:(NSEntityDescription *)entity;

#pragma mark - Connecting
- (void) _initializeSocketConnection;
- (void) _sendConnectMessage;

#pragma mark - Disconnecting
- (void) disconnect;

#pragma mark - Messaging
- (void)sendMessage:(ATMessage *)message;
- (void) _didReceiveServerPush:(NSDictionary *)data;

#pragma mark - Requests
- (void)get;

#pragma mark - Objects
- (void)_applyObjectMessage:(NSDictionary *)content;
- (void)_postObjectUpdateNotification:(NSManagedObject *)object;


#pragma mark - Responding to changes in app objects
- (void) _didChangeAppObject:(NSNotification *)notification;
#pragma mark Marking objects
- (void) _markAppObjectChanged:(NSManagedObject *)object;
- (void) _markAppObjectSynchronized:(NSManagedObject *)appObject;
- (BOOL) _isAppObjectChanged:(NSManagedObject *)appObject;
- (void) _markAppObjectDeleted:(NSManagedObject *)appObject;
- (void)addObjectsFromAppContext; /**< Finds objects in app context that are not yet managed by
                                   Atmosphere, adds them to meta context and marks them as changed. */

#pragma mark - Syncing
- (void) _startSync;
- (void) _sync;
- (void) _syncMetaObject:(ATObject *)metaObject;

#pragma mark - Managing local objects
// - (ATObject *) _findOrCreateObjectWithATID:(NSString *)atID;
- (ATObject *) _objectWithATID:(NSString *)atID;
- (ATObject *) _createObjectWithATID:(NSString *)atID;
- (ATObject *) _createObject;
- (ATObject *) _objectForAppObject:(NSManagedObject *)appObject;
- (ATObject *)_existingMetaObjectForAppObject:(NSManagedObject *)appObject;

#pragma mark - Managing app objects
- (NSManagedObject *) _appObjectForObject:(ATObject *)object;
- (NSManagedObject *) _createAppObjectWithLocalEntityName:(NSString *)localEntityName;
#pragma mark Updating
- (void) _updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data relations:(NSArray *)relations;
- (void) _updateAppObject:(NSManagedObject *)appObject withData:(NSDictionary *)data;
- (void) _updateAppObject:(NSManagedObject *)appObject withRelations:(NSArray *)relations;
- (void) _deleteAppObject:(NSManagedObject *)appObject;
#pragma mark Relations queue
- (void) _enqueueRelation:(NSDictionary *)relation forAppObject:(NSManagedObject *)appObject;
- (void) _applyRelations;
#pragma mark Serializing
- (NSDictionary *) _dataForAppObject:(NSManagedObject *)appObject;
- (NSArray *) _relationsForAppObject:(NSManagedObject *)appObject;
#pragma mark - Checking attribute changes
- (BOOL)_attributesChangedInAppObject:(NSManagedObject *)appObject;

@end