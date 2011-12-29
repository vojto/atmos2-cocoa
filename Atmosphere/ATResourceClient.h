//
//  ATResourceClient.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ATAppContext.h"

@class ATSynchronizer;

@interface ATResourceClient : NSObject

@property (assign) ATSynchronizer *sync;
@property (retain) RKClient *client;

#pragma mark - Fetching entities
- (void)fetchEntity:(NSString *)entityName;

#pragma mark - Responding to fetch results
- (void)didFetchItem:(NSDictionary *)item withURI:(ATObjectURI)uri;

@end
