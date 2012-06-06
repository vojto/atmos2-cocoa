//
//  ATObjectSaveRequest.h
//  Atmosphere
//
//  Created by Rinik Vojto on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

@class ATSynchronizer;
@class ATResourceClient;

@interface ATObjectSaveRequest : NSObject <RKRequestDelegate>

@property (assign) ATSynchronizer *sync;
@property (assign) ATResourceClient *resourceClient;
@property (assign) RKClient *networkClient;
@property (retain) NSDictionary *options;
@property (retain) NSManagedObject *object;

- (id)initWithResourceClient:(ATResourceClient *)client object:(NSManagedObject *)object options:(NSDictionary *)options;

- (void)send;


@end
