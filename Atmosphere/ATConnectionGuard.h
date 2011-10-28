//
//  ATConnectionGuard.h
//  Atmosphere
//
//  Created by Vojto Rinik on 10/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ATClient;

@interface ATConnectionGuard : NSObject {
    ATClient *client;
    BOOL isRunning;
}

@property (assign) ATClient *client;

- (void)start;
- (void)stop;

- (void)_checkConnection;


@end
