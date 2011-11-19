//
//  ATConnectionGuard.m
//  Atmosphere
//
//  Created by Vojto Rinik on 10/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATConnectionGuard.h"
#import "ATClient.h"

@implementation ATConnectionGuard

@synthesize client;

- (void)start {
    RKAssert(self.client, @"Cannot start guard without client");
    
    isRunning = YES;
    [self _checkConnection];
}

- (void)_checkConnection {
    if (!isRunning) return;
    
    ASLogInfo(@"[Guard] Checking connection");
    
    if ([client isConnected]) {
    } else {
        ASLogWarning(@"[Guard] Not connected! Connecting.");
        [client connect];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_checkConnection) withObject:nil afterDelay:60];
}

- (void)stop {
    isRunning = NO;
}

@end
