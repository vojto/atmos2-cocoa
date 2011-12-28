//
//  ATMessageClient.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SocketIO.h"
#import "ATMessage.h"

@class ATClient;

/**
 * ATMessageClient is responsible for dealing with live connection
 * for push updates and notifications.
 */
@interface ATMessageClient : NSObject <SocketIODelegate> {
    BOOL _isRunning;
    
    ATClient *_sync;
    
    /** Connection */
    NSString *_host;
    NSInteger _port;
    SocketIO *_connection;
}

@property (assign) ATClient *sync;
@property (nonatomic, retain) NSString *host;
@property (assign) NSInteger port;
@property (nonatomic, retain) SocketIO *connection;

#pragma mark - Lifecycle
- (id)initWithHost:(NSString *)aHost port:(NSInteger)aPort synchronizer:(ATClient *)aSync;

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
