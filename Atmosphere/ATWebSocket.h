//
//  ATWebSocket.h
//  Edukit
//
//  Created by Vojto Rinik on 7/1/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import "WebSocket.h"
#import "ATMessage.h"

@interface ATWebSocket : WebSocket

- (void) sendMessage:(ATMessage *)message;

@end
