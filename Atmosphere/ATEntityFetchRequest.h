//
//  ATEntityFetchRequest.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "ATSynchronizer.h"

@class ATResourceClient;

@interface ATEntityFetchRequest : NSObject <RKRequestDelegate>

@property (assign) ATResourceClient *resourceClient;
@property (assign) RKClient *networkClient;
@property (retain) NSString *entity;

- (id)initWithResourceClient:(ATResourceClient *)client entity:(NSString *)entity;

- (void)send;

- (ATObjectURI)objectURIFromItem:(NSDictionary *)item;

@end
