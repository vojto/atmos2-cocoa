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

#import "ATSynchronizer.h"
#import "ATObject.h"
#import "NSManagedObject+ATAdditions.h"
#import "ASIHTTPRequest.h"
#import "NSObject+JSON.h"
#import "ATMetaContext.h"
#import "ATAppContext.h"
#import "ATObjectURI.h"

// NSString * const ATMessageEntityKey = @"entity";

NSString * const ATDidUpdateObjectNotification = @"ATDidUpdateObjectNotification";

@implementation ATSynchronizer

@synthesize metaContext=_metaContext, appContext=_appContext, mappingHelper=_mappingHelper;
@synthesize messageClient=_messageClient, resourceClient=_resourceClient;
@synthesize authKey=_authKey;
@synthesize delegate;

#pragma mark - Lifecycle

- (id)initWithAppContext:(NSManagedObjectContext *)context {
    if ((self = [self init])) {
        _needsSync = YES;
        
        self.metaContext = [ATMetaContext restore];
        NSLog(@"Meta context: %@", self.metaContext);
        [self.metaContext save];
        self.appContext = [[[ATAppContext alloc] initWithSynchronizer:self appContext:context] autorelease];
        self.mappingHelper = [[[ATMappingHelper alloc] init] autorelease];
        self.messageClient = [[[ATMessageClient alloc] initWithSynchronizer:self] autorelease];
        self.resourceClient = [[[ATResourceClient alloc] initWithSynchronizer:self] autorelease];
        
        [self _registerForAppNotifications];
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
    [self.metaContext save];
    [self _sync];
    [self.messageClient disconnect];
}

#pragma mark Memory Management

- (void) dealloc {
    [_appContext release];
    [_authKey release];
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

#pragma mak - Resource Methods

- (void)fetchEntity:(NSString *)entityName {
    [self.resourceClient fetchEntity:entityName];
}

- (void)syncObject:(NSManagedObject *)appObject {
    if (![appObject valueForKey:@"identifier"]) {
        // Generate a new identifier
        [appObject setValue:[RNUtil uuidString] forKey:@"identifier"];
    }
    
    // TOOD: Save locally here
    
    ATObjectURI uri = [self.appContext URIOfAppObject:appObject];
    [self.metaContext markURIChanged:uri];
    // MetaContext.Mark object changed
    // this.Sync
}

#pragma mark - Working with objects

- (void)updateObjectAtURI:(ATObjectURI)uri withDictionary:(NSDictionary *)data {
    NSManagedObject *object = [self.appContext appObjectAtURI:uri];
    if (!object) {
        object = [self.appContext createAppObjectAtURI:uri];
        ASLogInfo(@"Created object %@", uri.identifier);
    } else {
        ASLogInfo(@"Found existing object %@", uri.identifier);
    }
    [self.appContext updateAppObject:object withDictionary:data];
}

- (void)_postObjectUpdateNotification:(NSManagedObject *)object {
    NSNotification *notification = [NSNotification notificationWithName:ATDidUpdateObjectNotification object:object];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark - Responding to changes in app objects

- (void) _didChangeAppObject:(NSNotification *)notification {
    /*
    ASLogInfo(@"App object just changed. %d", (int)[self.appContext hasChanges]);
    NSDictionary *userInfo = [notification userInfo];
    for (NSManagedObject *updatedObject in [userInfo valueForKey:NSUpdatedObjectsKey]) {
        if (![self.appContext attributesChangedInAppObject:updatedObject]) continue;
        [self _markAppObjectChanged:updatedObject];
    }
    NSSet *insertedObjects = [userInfo valueForKey:NSInsertedObjectsKey];
    NSError *error = nil;
    [self.appContext obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
    if (error) ASLogError(@"Error obtaining permanent IDs: %@", error);
    for (NSManagedObject *insertedObject in insertedObjects) {
//        ATObject *metaObject = [self _objectForAppObject:insertedObject];
        (void)[self.metaContext objectForAppObject:insertedObject];
        [self _markAppObjectChanged:insertedObject];
//        [self _saveContext];
    }
    for (NSManagedObject *deletedObject in [userInfo valueForKey:NSDeletedObjectsKey]) {
        [self _markAppObjectDeleted:deletedObject];
    }
    [self startSync];
    */
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

@end
