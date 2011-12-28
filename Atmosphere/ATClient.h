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

#import "ATMessage.h"
#import "ATObject.h"
#import "ATMetaContext.h"
#import "ATMappingHelper.h"
#import "ATMessageClient.h"
#import "ATResourceClient.h"

extern NSString * const ATDidUpdateObjectNotification;

@class ATClient;

@protocol ATClientDelegate <NSObject>

- (void) clientAuthDidSucceed:(ATClient *)client;
- (void) clientAuthDidFail:(ATClient *)client;

@end

@interface ATClient : NSObject {
   
    /** Atmosphere */
    ATMetaContext *_metaContext;
    ATMappingHelper *_mappingHelper;
    
    /** Networking clients */
    ATMessageClient *_messageClient;
    ATResourceClient *_resourceClient;

    
    /** App */
    NSManagedObjectContext *_appContext;
    
    /** State */

    NSString *_authKey;
    BOOL _needsSync;
    NSMutableArray *_relationsQueue;
    
    /** Schema */
    NSManagedObjectContext *_context;
    NSEntityDescription *_objectEntity;
    
    /** Delegate */
    id<ATClientDelegate> delegate;
}

@property (nonatomic, retain) ATMetaContext *metaContext;
@property (nonatomic, retain) ATMappingHelper *mappingHelper;
@property (nonatomic, retain) ATMessageClient *messageClient;
@property (nonatomic, retain) ATResourceClient *resourceClient;

@property (nonatomic, retain) NSString *authKey;

@property (nonatomic, assign) NSManagedObjectContext *appContext;
@property (assign) id<ATClientDelegate> delegate;

#pragma mark - Lifecycle
- (id) initWithHost:(NSString *)aHost port:(NSInteger)aPort appContext:(NSManagedObjectContext *)context;
- (NSManagedObjectContext *) _createContext;
- (void)_registerForAppNotifications;
/**
 * Ends active connections, saves changes
 */
- (void)close;

#pragma mark - Authentication
- (NSString *)authKeyOrNull;

#pragma mark - Working with contexts
- (BOOL) _saveContext;

#pragma mark - Objects
- (void)applyObjectMessage:(NSDictionary *)content;
- (void)_postObjectUpdateNotification:(NSManagedObject *)object;

#pragma mark - Responding to changes in app objects
- (void)_didChangeAppObject:(NSNotification *)notification;
#pragma mark Marking objects
- (void)_markAppObjectChanged:(NSManagedObject *)object;
- (void)_markAppObjectSynchronized:(NSManagedObject *)appObject;
- (BOOL)_isAppObjectChanged:(NSManagedObject *)appObject;
- (void)_markAppObjectDeleted:(NSManagedObject *)appObject;
- (void)addObjectsFromAppContext; /**< Finds objects in app context that are not yet managed by
                                   Atmosphere, adds them to meta context and marks them as changed. */

#pragma mark - Syncing
- (void)startSync;
- (void)_sync;
- (void)_syncMetaObject:(ATObject *)metaObject;

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