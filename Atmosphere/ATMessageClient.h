//
//  ATMessageClient.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SocketIO.h"
#import "ATMessage.h"

extern NSString * const ATMessageATIDKey;
extern NSString * const ATMessageObjectKey;
extern NSString * const ATMessageObjectDataKey;
extern NSString * const ATMessageObjectDeletedKey;
extern NSString * const ATMessageObjectRelationsKey;
extern NSString * const ATMessageVersionKey;
extern NSString * const ATMessageAuthKeyKey;

@class ATSynchronizer;

/**
 * ATMessageClient is responsible for dealing with live connection
 * for push updates and notifications.
 */
@interface ATMessageClient : NSObject <SocketIODelegate> {
    BOOL _isRunning;
    
    ATSynchronizer *_sync;
    
    /** Connection */
    NSString *_host;
    NSInteger _port;
    SocketIO *_connection;
}

@property (assign) ATSynchronizer *sync;
@property (nonatomic, retain) NSString *host;
@property (assign) NSInteger port;
@property (nonatomic, retain) SocketIO *connection;

#pragma mark - Lifecycle
- (id)initWithSynchronizer:(ATSynchronizer *)sync;

#pragma mark - Connecting
- (void)connect;
- (BOOL)isConnected;
- (void)_initializeSocketConnection;
- (void)_sendConnectMessage;

#pragma mark - Disconnecting
- (void) disconnect;

#pragma mark - Auth
- (void)_didReceiveServerAuthFailure:(NSDictionary *)data;
- (void)_didReceiveServerAuthSuccess:(NSDictionary *)data;

#pragma mark - Messaging
- (void)sendMessage:(ATMessage *)message;
- (void) _didReceiveServerPush:(NSDictionary *)data;

@end
