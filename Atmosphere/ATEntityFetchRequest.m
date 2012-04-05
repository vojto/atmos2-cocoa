//
//  ATEntityFetchRequest.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RNUtil.h"

#import "ATEntityFetchRequest.h"
#import "ATResourceClient.h"

@implementation ATEntityFetchRequest

@synthesize resourceClient = _resourceClient, networkClient = _networkClient, entity = _entity;

#pragma mark - Lifecycle

- (id)initWithResourceClient:(ATResourceClient *)client entity:(NSString *)entity {
    if ((self = [super init])) {
        self.resourceClient = client;
        self.networkClient = client.client;
        self.entity = entity;
    }
    return self;
}

- (void)dealloc {
    self.entity = nil;
    [super dealloc];
}

#pragma mark - Sending

- (void)send {
    // TODO: Translate self.entity to path
    ATRoute route = [self.resourceClient routeForEntity:self.entity action:ATActionIndex];
    ASLogInfo(@"Making request %d %@", route.method, route.path);
    [self.resourceClient loadRoute:route params:nil delegate:self];
}

#pragma mark - Processing results

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    if ([response statusCode] != 200) {
        ASLogError(@"[ATEntityFetchRequest] Unexpected response code %d (expecting 200)", [response statusCode]);
        return;
    }
    ASLogInfo(@"[ATEntityFetchRequest] Done fetching: %@", [response bodyAsString]);
    id items = [response parsedBody:nil];
    RKAssert([items isKindOfClass:[NSArray class]], @"Expected result to by an array");
    for (NSDictionary *item in (NSArray *)items) {
        ATObjectURI uri = [self objectURIFromItem:item];
        [self.resourceClient didFetchItem:item withURI:uri];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    NSLog(@"Request failed: %@", error);
}

#pragma mark - Helper methods

- (ATObjectURI)objectURIFromItem:(NSDictionary *)item {
    // TODO: _id should be configurable (where?)
    NSString *ident = [item objectForKey:@"_id"];
    return ATObjectURIMake(self.entity, ident);
}

@end
