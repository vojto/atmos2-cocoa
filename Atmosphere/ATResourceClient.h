//
//  ATResourceClient.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ATAppContext.h"
#import "ATObjectURI.h"
#import "ATMetaObject.h"

extern NSString * const ATActionIndex;
extern NSString * const ATActionShow;
extern NSString * const ATActionCreate;
extern NSString * const ATActionUpdate;
extern NSString * const ATActionDestroy;

typedef struct _ATRoute {
    RKRequestMethod method;
    __unsafe_unretained NSString *path; // TODO: This is wrong and it should be refactored
} ATRoute;

ATRoute ATRouteMake(RKRequestMethod method, NSString *path);

@class ATSynchronizer;

@interface ATResourceClient : NSObject

@property (assign) ATSynchronizer *sync;
@property (retain) RKClient *client;
@property (retain) NSDictionary *routes;
@property (retain) NSString *IDField;

#pragma mark - Lifecycle
- (id)initWithSynchronizer:(ATSynchronizer *)sync;
- (void)setBaseURL:(NSString *)url;
- (void)addHeader:(NSString *)name withValue:(NSString *)value;
- (void)removeHeader:(NSString *)name;

#pragma mark - Fetching objects
- (void)fetchEntity:(NSString *)entityName;
- (void)didFetchItem:(NSDictionary *)item withURI:(ATObjectURI *)uri;

#pragma mark - Saving objects
- (void)saveObject:(NSManagedObject *)object;
- (void)saveObject:(NSManagedObject *)object options:(NSDictionary *)options;

#pragma mark - Deleting objects
/**
 This method takes object URI as argument because the app object
 might be removed from the memory already. */
- (void)deleteObject:(ATObjectURI *)objectURI;

#pragma mark - Requests
- (void)loadRoute:(ATRoute)route params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate;
- (void)loadRoutesFromResource:(NSString *)resourceName;
- (void)loadPath:(NSString *)path callback:(RKObjectLoaderDidLoadObjectBlock)callback;

#pragma mark - Routing
- (ATRoute)routeForEntity:(NSString *)entity action:(NSString *)action;
- (ATRoute)routeForEntity:(NSString *)entity action:(NSString *)action params:(NSDictionary *)options;
- (NSString *)_defaultRouteStringForEntity:(NSString *)entity action:(NSString *)action;

@end
