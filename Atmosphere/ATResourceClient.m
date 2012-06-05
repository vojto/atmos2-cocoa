//
//  ATResourceClient.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RNUtil.h"

#import "ATSynchronizer.h"
#import "ATResourceClient.h"
#import "ATEntityFetchRequest.h"
#import "ATObjectSaveRequest.h"
#import "RKClient+ATAdditions.h"
#import "NSString+ATAdditions.h"
#import "ATObjectDeleteRequest.h"

NSString * const ATActionIndex = @"index";
NSString * const ATActionShow = @"show";
NSString * const ATActionCreate = @"create";
NSString * const ATActionUpdate = @"update";
NSString * const ATActionDestroy = @"destroy";

ATRoute ATRouteMake(RKRequestMethod method, NSString *path) {
    ATRoute route;
    route.method = method;
    route.path = path;
    return route;
}

@implementation ATResourceClient

@synthesize sync = _sync;
@synthesize client = _client;
@synthesize routes = _routes;
@synthesize IDField = _IDField;

/*****************************************************************************/
#pragma mark - Lifecycle
/*****************************************************************************/

- (id)initWithSynchronizer:(ATSynchronizer *)sync {
    if ((self = [super init])) {
        self.sync = sync;
        self.client = [[[RKClient alloc] init] autorelease];
        ASLogInfo(@"Created client: %@", self.client);
        self.IDField = @"_id"; // Default ID field
    }
    
    return self;
}

- (void)dealloc {
    self.client = nil;
    [super dealloc];
}

- (void)setBaseURL:(NSString *)url {
    [self.client setBaseURL:[RKURL URLWithString:url]];
}

- (void)addHeader:(NSString *)name withValue:(NSString *)value {
    [self.client.HTTPHeaders setObject:value forKey:name];
}

- (void)removeHeader:(NSString *)name {
    [self.client.HTTPHeaders removeObjectForKey:name];
}

/*****************************************************************************/
#pragma mark - Fetching entities
/*****************************************************************************/

- (void)fetchEntity:(NSString *)entityName {
    // TODO: Routing based on entity name
    ATEntityFetchRequest *fetchRequest = [[ATEntityFetchRequest alloc] initWithResourceClient:self entity:entityName];
    [fetchRequest send];
    // TODO: Memory management
}

- (void)didFetchItem:(NSDictionary *)item withURI:(ATObjectURI *)uri {
    [self.sync updateObjectAtURI:uri withDictionary:item];
}

/*****************************************************************************/
#pragma mark - Saving objects
/*****************************************************************************/

- (void)saveObject:(NSManagedObject *)object {
    [self saveObject:object options:[NSDictionary dictionary]];
}

- (void)saveObject:(NSManagedObject *)object options:(NSDictionary *)options {
    ATObjectSaveRequest *request = [[ATObjectSaveRequest alloc] initWithResourceClient:self object:object options:options];
    [request send];
}

/*****************************************************************************/
#pragma mark - Deleting objects
/*****************************************************************************/

- (void)deleteObject:(ATObjectURI *)objectURI {
    ATObjectDeleteRequest *request = [[ATObjectDeleteRequest alloc] initWithResourceClient:self objectURI:objectURI];
    [request send];
}

/*****************************************************************************/
#pragma mark - Requests
/*****************************************************************************/

- (void)loadRoute:(ATRoute)route params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate {
    [self.client load:route.path method:route.method params:params delegate:delegate];
}

- (void)loadRoutesFromResource:(NSString *)resourceName {
    self.routes = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"]];
}

- (void)loadPath:(NSString *)path callback:(RKObjectLoaderDidLoadObjectBlock)callback {
    RKRequest *request = [self.client requestWithResourcePath:path];
    request.onDidLoadResponse = callback;
    request.onDidFailLoadWithError = ^(NSError *error) {
        ASLogWarning(@"Failed to load %@: %@", path, error);
    };
    [request send];
}

/*****************************************************************************/
#pragma mark - Routing
/*****************************************************************************/

- (ATRoute)routeForEntity:(NSString *)entity action:(NSString *)action {
    return [self routeForEntity:entity action:action params:nil];
}

- (ATRoute)routeForEntity:(NSString *)entity action:(NSString *)action params:(NSDictionary *)params {
    NSDictionary *routes = [self.routes objectForKey:entity];
    NSString *routeString = [routes objectForKey:action];
    if (!routeString) {
        routeString = [self _defaultRouteStringForEntity:entity action:action];
    }
    NSArray *comps = [routeString componentsSeparatedByString:@" "];
    RKAssert(([comps count] == 2), @"Unknown route format '%@'. Please use 'METHOD /path'", routeString);
    NSString *method = [[comps objectAtIndex:0] lowercaseString];
    NSString *path = [comps objectAtIndex:1];
    
    // Apply params in the route
    for (NSString *key in [params allKeys]) {
        path = [path stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@":%@", key] withString:[params objectForKey:key]];
    }
    
    ASLogInfo(@"[ATResourceClient] Built path: %@", path);
    
    ATRoute route;
    route.path = path;
    if ([method isEqualToString:@"get"]) route.method = RKRequestMethodGET;
    else if ([method isEqualToString:@"post"]) route.method = RKRequestMethodPOST;
    else if ([method isEqualToString:@"put"]) route.method = RKRequestMethodPUT;
    else if ([method isEqualToString:@"delete"]) route.method = RKRequestMethodDELETE;
    else RKAssert(false, @"Unknown method %@", method);
    
    return route;
}

- (NSString *)_defaultRouteStringForEntity:(NSString *)entity action:(NSString *)action {
    entity = [[entity lowercaseString] pluralizedString];
    
    if ([action isEqualToString:@"index"]) {
        return [NSString stringWithFormat:@"get /%@", entity];
    } else if ([action isEqualToString:@"create"]) {
        return [NSString stringWithFormat:@"post /%@", entity];
    } else if ([action isEqualToString:@"update"]) {
        return [NSString stringWithFormat:@"put /%@/:id", entity];
    } else if ([action isEqualToString:@"destroy"]) {
        return [NSString stringWithFormat:@"delete /%@/:id", entity];
    } else {
        RKAssert(false, @"Can't create default route for action %@", action);
        return nil;
    }
}

@end
