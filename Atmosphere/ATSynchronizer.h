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
#import "ATAppContext.h"
#import "ATMappingHelper.h"
#import "ATMessageClient.h"
#import "ATResourceClient.h"

extern NSString * const ATDidUpdateObjectNotification;

@class ATSynchronizer;

@protocol ATSynchronizerDelegate <NSObject>

- (void) clientAuthDidSucceed:(ATSynchronizer *)client;
- (void) clientAuthDidFail:(ATSynchronizer *)client;

@end

@interface ATSynchronizer : NSObject {
   
    /** Helper */
    ATMappingHelper *_mappingHelper;
    
    /** Context */
    ATMetaContext *_metaContext;
    ATAppContext *_appContext;
    
    /** Networking clients */
    ATMessageClient *_messageClient;
    ATResourceClient *_resourceClient;

    /** State */
    NSString *_authKey;
    BOOL _needsSync;
    
    /** Delegate */
    id<ATSynchronizerDelegate> delegate;
}

@property (nonatomic, retain) ATMetaContext *metaContext;
@property (nonatomic, retain) ATAppContext *appContext;
@property (nonatomic, retain) ATMappingHelper *mappingHelper;
@property (nonatomic, retain) ATMessageClient *messageClient;
@property (nonatomic, retain) ATResourceClient *resourceClient;

@property (nonatomic, retain) NSString *authKey;

@property (assign) id<ATSynchronizerDelegate> delegate;

#pragma mark - Lifecycle
- (id) initWithHost:(NSString *)aHost port:(NSInteger)aPort appContext:(NSManagedObjectContext *)context;
- (void)_registerForAppNotifications;
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

#pragma mark - Marking objects
- (void)_markAppObjectChanged:(NSManagedObject *)object;
- (void)_markAppObjectSynchronized:(NSManagedObject *)appObject;
- (BOOL)_isAppObjectChanged:(NSManagedObject *)appObject;
- (void)_markAppObjectDeleted:(NSManagedObject *)appObject;

#pragma mark - Syncing
- (void)startSync;
- (void)_sync;
- (void)_syncMetaObject:(ATObject *)metaObject;

@end