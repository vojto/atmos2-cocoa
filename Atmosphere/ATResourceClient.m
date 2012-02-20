//
//  ATResourceClient.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "ATSynchronizer.h"
#import "ATResourceClient.h"
#import "ATEntityFetchRequest.h"
#import "RKClient+ATAdditions.h"

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

#pragma mark - Lifecycle

- (id)initWithSynchronizer:(ATSynchronizer *)sync {
    if ((self = [super init])) {
        self.sync = sync;
        self.client = [[[RKClient alloc] init] autorelease];
        NSLog(@"Created client: %@", self.client);
    }
    
    return self;
}

- (void)dealloc {
    self.client = nil;
}

- (void)setBaseURL:(NSString *)url {
    [self.client setBaseURL:url];
}

- (void)addHeader:(NSString *)name withValue:(NSString *)value {
    [self.client.HTTPHeaders setObject:value forKey:name];
}

#pragma mark - Fetching entities

- (void)fetchEntity:(NSString *)entityName {
    // TODO: Routing based on entity name
    ATEntityFetchRequest *fetchRequest = [[ATEntityFetchRequest alloc] initWithResourceClient:self entity:entityName];
    [fetchRequest send];
}

#pragma mark - Responding to fetch results

- (void)didFetchItem:(NSDictionary *)item withURI:(ATObjectURI)uri {
    [self.sync updateObjectAtURI:uri withDictionary:item];
}

#pragma mark - Making requests

- (void)loadRoute:(ATRoute)route params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate {
    [self.client load:route.path method:route.method params:params delegate:delegate];
}

#pragma mark - Managing routes
- (void)loadRoutesFromResource:(NSString *)resourceName {
    self.routes = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"]];
}

// TODO: Auto-generate route if none found
- (ATRoute)routeForEntity:(NSString *)entity action:(NSString *)action {
    NSDictionary *routes = [self.routes objectForKey:entity];
    NSString *routeString = [routes objectForKey:action];
    RKAssert(routeString, @"No route found for action %@ of entity %@", action, entity);
    NSArray *comps = [routeString componentsSeparatedByString:@" "];
    RKAssert(([comps count]==2), @"Unknown route format '%@'. Please use 'METHOD /path'", routeString);
    NSString *method = [[comps objectAtIndex:0] lowercaseString];
    NSString *path = [comps objectAtIndex:1];
    
    ATRoute route;
    route.path = path; // Retain maybe?? Nope, it's retain by routes dictionary.
    if ([method isEqualToString:@"get"]) route.method = RKRequestMethodGET;
    else if ([method isEqualToString:@"post"]) route.method = RKRequestMethodPOST;
    else if ([method isEqualToString:@"put"]) route.method = RKRequestMethodPUT;
    else if ([method isEqualToString:@"delete"]) route.method = RKRequestMethodDELETE;
    else RKAssert(false, @"Unknown method %@", method);
    
    return route;
}

@end
