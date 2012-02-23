//
//  ATObjectSaveRequest.h
//  Atmosphere
//
//  Created by Rinik Vojto on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

@class ATResourceClient;

@interface ATObjectSaveRequest : NSObject <RKRequestDelegate>

@property (assign) ATResourceClient *resourceClient;
@property (assign) RKClient *networkClient;
@property (retain) NSDictionary *options;
@property (assign) NSManagedObject *object;

- (id)initWithResourceClient:(ATResourceClient *)client object:(NSManagedObject *)object options:(NSDictionary *)options;

- (void)send;

- (NSString *)_paramWrapperForObject:(NSManagedObject *)object;

@end
