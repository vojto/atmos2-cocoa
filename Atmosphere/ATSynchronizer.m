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
#import <SBJson/NSObject+SBJson.h>

#import "ATSynchronizer.h"
#import "NSManagedObject+ATAdditions.h"
#import "ASIHTTPRequest.h"
#import "ATMetaContext.h"
#import "ATMetaObject.h"
#import "ATAppContext.h"
#import "ATObjectURI.h"
#import "RNUtil.h"

// NSString * const ATMessageEntityKey = @"entity";

NSString * const ATDidUpdateObjectNotification = @"ATDidUpdateObjectNotification";
NSString * const kATAuthChangedNotification = @"ATAuthChangedNotification";

@implementation ATSynchronizer

@synthesize metaContext=_metaContext, appContext=_appContext, mappingHelper=_mappingHelper;
@synthesize messageClient=_messageClient, resourceClient=_resourceClient;
@synthesize delegate;
@synthesize authentication;

/*****************************************************************************/
#pragma mark - Lifecycle
/*****************************************************************************/

- (id)initWithAppContext:(NSManagedObjectContext *)context {
    if ((self = [self init])) {
        [RNUtil initLogging];
        
        _isSyncScheduled = NO;
        
        self.metaContext = [ATMetaContext restore];
        [self.metaContext save];
        self.appContext = [[[ATAppContext alloc] initWithSynchronizer:self appContext:context] autorelease];
        self.mappingHelper = [[[ATMappingHelper alloc] init] autorelease];
        self.messageClient = [[[ATMessageClient alloc] initWithSynchronizer:self] autorelease];
        self.resourceClient = [[[ATResourceClient alloc] initWithSynchronizer:self] autorelease];
        self.authentication = [[ATAuthentication alloc] initWithSynchronizer:self];
        self.authentication.resourceClient = self.resourceClient;
        
        [self startAutosync];
        [self startSync];
        
    }
    return self;
}

- (void)close {
    [self.metaContext save];
    [self.messageClient disconnect];
}

/*****************************************************************************/
#pragma mark Memory Management
/*****************************************************************************/

- (void) dealloc {
    [_appContext release];
    self.metaContext = nil;
    self.mappingHelper = nil;
    self.messageClient = nil;
    self.resourceClient = nil;
    [super dealloc];
}

/*****************************************************************************/
#pragma mark - Authentication
/*****************************************************************************/

- (BOOL)isLoggedIn {
    return [self.authentication isLoggedIn];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
    return [self.authentication loginWithUsername:username
                                         password:password];
}

- (void)logout {
    return [self.authentication logout];
}

- (void)signupWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password {
    return [self.authentication signupWithUsername:username
                                             email:email
                                          password:password];
}

- (NSDictionary *)currentUser {
    return self.authentication.currentUser;
}

/*****************************************************************************/
#pragma mark - Resource Methods
/*****************************************************************************/

- (void)setBaseURL:(NSString *)baseURL {
    [self.resourceClient setBaseURL:baseURL];
}

- (void)loadRoutesFromResource:(NSString *)resourceName {
    [self.resourceClient loadRoutesFromResource:resourceName];
}

- (void)setIDField:(NSString *)IDField {
    [self.resourceClient setIDField:IDField];
}

- (void)fetchEntity:(NSString *)entityName {
    [self.resourceClient fetchEntity:entityName];
}

/*****************************************************************************/
#pragma mark - Syncing
/*****************************************************************************/

- (void)syncObject:(NSManagedObject *)appObject {
    if (![appObject valueForKey:@"identifier"]) {
        [appObject setValue:[RNUtil uuidString] forKey:@"identifier"];
    }
    // [self.appContext save:nil]; // TODO: Remove?
    
    ATObjectURI *uri = [self.appContext URIOfAppObject:appObject];
    [self.metaContext markURIChanged:uri];
    
    [self startSync];
}

- (void)deleteOject:(NSManagedObject *)appObject {
    ATObjectURI *uri = [self.appContext URIOfAppObject:appObject];
    [self.metaContext markURIDeleted:uri];
    [self startSync];
}

- (void)startSync {
    if (!_isSyncScheduled) {
        _isSyncScheduled = YES;
        [self performSelectorOnMainThread:@selector(sync) withObject:nil waitUntilDone:NO];
    }
}

- (void)sync {
    for (ATMetaObject *meta in [self.metaContext changedObjects]) {
        NSLog(@"Syncing %@", meta);
        
        if (meta.isDeleted && meta.isLocalOnly) {
            ASLogInfo(@"Removing meta object because it's deleted and local only: %@", meta);
            [self.metaContext deleteObjectAtURI:meta.uri];
            [self.metaContext save];
        } else if (meta.isDeleted && !meta.isLocalOnly) {
            [self.resourceClient deleteObject:meta.uri];
        } else {
            NSString *action = meta.isLocalOnly ? ATActionCreate : ATActionUpdate;
            NSManagedObject *object = [self.appContext objectAtURI:meta.uri];
            [self.resourceClient saveObject:object options:[NSDictionary dictionaryWithObject:action forKey:@"action"]];
        }
        
    }
    _isSyncScheduled = NO;
}

/*****************************************************************************/
#pragma mark - Working with objects
/*****************************************************************************/

- (void)updateObjectAtURI:(ATObjectURI *)uri withDictionary:(NSDictionary *)data {
    NSManagedObject *object = [self.appContext objectAtURI:uri];
    if (!object) {
        object = [self.appContext createAppObjectAtURI:uri];
        ASLogInfo(@"Created object %@", uri.identifier);
    } else {
        ASLogInfo(@"Found existing object %@", uri.identifier);
    }
    [self.appContext updateAppObject:object withDictionary:data];
    
    // 03 Mark meta contxt
    [self.metaContext markURISynced:uri];
    [self.metaContext save];
}

- (void)changeURIFrom:(ATObjectURI *)original to:(ATObjectURI *)changed {
    ASLogInfo(@"Changing URIs: %@/%@ --> %@/%@", original.entity, original.identifier, changed.entity, changed.identifier);

    [self.appContext changeIDTo:changed.identifier atURI:original];
    [self.metaContext changeIDTo:changed.identifier atURI:original];
}

/*****************************************************************************/
#pragma mark - Autosync
/*****************************************************************************/

- (void)startAutosync {
    RKAssert(self.appContext, @"App context shouldn't be nil");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didChangeAppObject:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.appContext.managedContext];
}

- (void)stopAutosync {
    
}

- (void)_didChangeAppObject:(NSNotification *)notification {
    ASLogInfo(@"App object just changed. %d", (int)[self.appContext hasChanges]);
    NSDictionary *userInfo = [notification userInfo];
    for (NSManagedObject *updatedObject in [userInfo valueForKey:NSUpdatedObjectsKey]) {
        if (![self.appContext attributesChangedInAppObject:updatedObject]) continue;
        [self syncObject:updatedObject];
    }
    NSSet *insertedObjects = [userInfo valueForKey:NSInsertedObjectsKey];
    NSError *error = nil;
    [self.appContext obtainPermanentIDsForObjects:[insertedObjects allObjects] error:&error];
    if (error) ASLogError(@"Error obtaining permanent IDs: %@", error);
    for (NSManagedObject *insertedObject in insertedObjects) {
//        ATObject *metaObject = [self _objectForAppObject:insertedObject];
        [self syncObject:insertedObject];
//        [self _saveContext];
    }
    for (NSManagedObject *deletedObject in [userInfo valueForKey:NSDeletedObjectsKey]) {
        // TODO: Handle deletion
        ASLogInfo(@"Object was deleted: %@", deletedObject);
        [self deleteOject:deletedObject];
    }
    [self startSync];
    [self.metaContext save];
    
    NSLog(@"%@", [self.metaContext valueForKey:@"_objects"]);
}




@end
