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
    
    RKLog(@"Checking connection");
    
    if ([client isConnected]) {
        RKLog(@"All good, connected...");
    } else {
        RKLog(@"Shit! We're not connected! Let's fix that.");
        [client connect];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_checkConnection) withObject:nil afterDelay:5*60];
}

- (void)stop {
    isRunning = NO;
}

@end
