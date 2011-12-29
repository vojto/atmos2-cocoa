//
//  ATResourceClient.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ATAppContext.h"

extern NSString * const ATActionIndex;
extern NSString * const ATActionShow;
extern NSString * const ATActionCreate;
extern NSString * const ATActionUpdate;
extern NSString * const ATActionDestroy;

typedef struct _ATRoute {
    RKRequestMethod method;
    NSString *path;
} ATRoute;

@class ATSynchronizer;

@interface ATResourceClient : NSObject

@property (assign) ATSynchronizer *sync;
@property (retain) RKClient *client;
@property (retain) NSDictionary *routes;

#pragma mark - Lifecycle
- (id)initWithSynchronizer:(ATSynchronizer *)sync;

#pragma mark - Fetching entities
- (void)fetchEntity:(NSString *)entityName;

#pragma mark - Responding to fetch results
- (void)didFetchItem:(NSDictionary *)item withURI:(ATObjectURI)uri;

#pragma mark - Making request
- (void)loadRoute:(ATRoute)route params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate;

#pragma mark - Managing routes
- (void)loadRoutesFromResource:(NSString *)resourceName;
- (ATRoute)routeForEntity:(NSString *)entity action:(NSString *)action;

@end
