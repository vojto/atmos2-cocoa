//
//  ATMessageClient.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RNUtil.h"

#import "ATMessageClient.h"
#import "ATSynchronizer.h"

NSString * const ATConnectClientMessage = @"client-connect";

NSString * const ATMessageServerPushType = @"server-push";
NSString * const ATMessageClientPushType = @"client-push";
NSString * const ATMessageServerAuthFailureType = @"server-auth-failure";
NSString * const ATMessageServerAuthSuccessType = @"server-auth-success";

NSString * const ATMessageATIDKey = @"object_atid";
NSString * const ATMessageObjectKey = @"object";
NSString * const ATMessageObjectDataKey = @"object_data";
NSString * const ATMessageObjectDeletedKey = @"object_deleted";
NSString * const ATMessageObjectRelationsKey = @"object_relations";
NSString * const ATMessageVersionKey = @"version";
NSString * const ATMessageAuthKeyKey = @"auth_key";

@implementation ATMessageClient

@synthesize sync=_sync, host=_host, port=_port, connection=_connection;

#pragma mark - Lifecycle

- (id)initWithSynchronizer:(ATSynchronizer *)sync {
    if ((self = [super init])) {
        self.sync = sync;
    }
    return self;
}

- (void)dealloc {
    self.connection = nil;
    self.host = nil;
}

#pragma mark - Connecting

- (void) connect {
    _isRunning = YES;
    [self _initializeSocketConnection];
}

- (BOOL)isConnected {
    return [_connection isConnected];
}

- (void) _initializeSocketConnection {
    [_connection disconnect];
    [_connection autorelease];
    ASLogInfo(@"Connecting to host: %@:%d", _host, _port);
    
    _connection = [[SocketIO alloc] initWithDelegate:self];
    [_connection connectToHost:_host onPort:_port];
}

- (void)socketIODidConnect:(SocketIO *)socket {
    ASLogInfo(@"Web Socket connection opened");
    [self _sendConnectMessage];
    [self.sync startSync];
}

- (void)_sendConnectMessage {
    // Send the "Connect Client" message
    NSNumber *version = [self.sync.metaContext versionAsNumber];
    NSString *authKey = [self.sync authKeyOrNull];
    ATMessage *connectMessage = [[ATMessage alloc] init];
    connectMessage.type = ATConnectClientMessage;
    connectMessage.content = [NSDictionary dictionaryWithObjectsAndKeys:
                              version, ATMessageVersionKey,
                              authKey, ATMessageAuthKeyKey,
                              nil];
    ASLogInfo(@"Sending connect message with version %@ and auth key %@", version, authKey);
    [self sendMessage:connectMessage];
}

#pragma mark Disconnecting

- (void)disconnect {
    _isRunning = NO;
    [_connection disconnect];
}

- (void)webSocketDidClose:(WebSocket *)webSocket {
    if (_isRunning) {
        //        ASLogInfo(@"Disconnected, reconnecting...");
        //        [self performSelector:@selector(connect) withObject:nil afterDelay:5];
    }
}

#pragma mark Authentication

- (void)_didReceiveServerAuthSuccess:(NSDictionary *)data {
    // TODO: Notification about auth success
    ASLogWarning(@"At this point, synchronization should be started");
    [self.sync startSync];
}

- (void)_didReceiveServerAuthFailure:(NSDictionary *)data {
    // TOOD: Post notification about auth failure
    ASLogWarning(@"[ATMessageClient] Authentication failure");
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


- (void)_didReceiveServerPush:(NSDictionary *)content {
    [self.sync applyObjectMessage:content];
}

@end
