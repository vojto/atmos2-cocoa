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
#import "ATMappingHelper.h"
#import "ATMessageClient.h"
#import "ATResourceClient.h"
#import "ATObjectURI.h"

@class ATAppContext;
@class ATMetaContext;

extern NSString * const ATDidUpdateObjectNotification;
extern NSString * const kATAuthChangedNotification;

@class ATSynchronizer;

@protocol ATSynchronizerDelegate <NSObject>

- (void) clientAuthDidSucceed:(ATSynchronizer *)client;
- (void) clientAuthDidFail:(ATSynchronizer *)client;

@end

@interface ATSynchronizer : NSObject {
   
    /** State */
    BOOL _isSyncScheduled;
    
}

@property (assign) id<ATSynchronizerDelegate> delegate;
@property (nonatomic, retain) ATMetaContext *metaContext;
@property (nonatomic, retain) ATAppContext *appContext;
@property (nonatomic, retain) ATMappingHelper *mappingHelper;
@property (nonatomic, retain) ATMessageClient *messageClient;
@property (nonatomic, retain) ATResourceClient *resourceClient;
@property (nonatomic, retain) NSString *authToken;
@property (nonatomic, retain) NSDictionary *currentUser;

#pragma mark - Lifecycle
- (id)initWithAppContext:(NSManagedObjectContext *)context;

- (void)close;

#pragma mark - Authentication
- (BOOL)isLoggedIn;
/**
 Will make HTTP request to login, get the token, then it will set the token
 as header.
 
 This method is tailor-made for atmos2-server. Eventually it should be customizable,
 but when using custom API, developer might just implement custom authentication
 mechanizm. */
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;
- (void)_rememberToken;
- (void)_restoreToken;
- (void)_useToken;
- (void)logout;

#pragma mark - Resource methods
- (void)loadRoutesFromResource:(NSString *)resourceName;
- (void)setBaseURL:(NSString *)baseURL;
- (void)setIDField:(NSString *)IDField;
- (void)fetchEntity:(NSString *)entityName;

#pragma mark - Syncing
- (void)syncObject:(NSManagedObject *)appObject;
- (void)deleteOject:(NSManagedObject *)appObject;
- (void)startSync;
- (void)sync;

#pragma mark - Objects
- (void)updateObjectAtURI:(ATObjectURI *)uri withDictionary:(NSDictionary *)data;
- (void)changeURIFrom:(ATObjectURI *)original to:(ATObjectURI *)changed;

#pragma mark - Auto sync
- (void)startAutosync;
- (void)stopAutosync;
- (void)_didChangeAppObject:(NSNotification *)notification;


@end