//
//  ATWebSocket.m
//  Edukit
//
//  Created by Vojto Rinik on 7/1/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import "WebSocket.h"
#import "ATWebSocket.h"

@implementation ATWebSocket

- (void) sendMessage:(ATMessage *)message {
    NSString *jsonString = [message JSONString];
    [self send:jsonString];
}

@end
