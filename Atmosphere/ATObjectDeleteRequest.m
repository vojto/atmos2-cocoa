//
//  ATObjectDeleteRequest.m
//  Atmosphere
//
//  Created by Rinik Vojto on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ATObjectDeleteRequest.h"
#import "ATResourceClient.h"
#import "RNUtil.h"
#import "ATMetaContext.h"

@implementation ATObjectDeleteRequest

@synthesize sync = _sync;
@synthesize resourceClient = _resourceClient, networkClient = _networkClient, objectURI = _objectURI;

- (id)initWithResourceClient:(ATResourceClient *)client objectURI:(ATObjectURI *)objectURI {
    if ((self = [super init])) {
        self.sync = client.sync;
        self.resourceClient = client;
        self.networkClient = client.client;
        self.objectURI = objectURI;
    }

    return self;
}

- (void)send {
    NSDictionary *routeParams = [NSDictionary dictionaryWithObject:self.objectURI.identifier forKey:@"id"];
    ATRoute route = [self.resourceClient routeForEntity:self.objectURI.entity action:ATActionDestroy params:routeParams];
    
    ASLogInfo(@"Sending delete request");
    
    [self.resourceClient loadRoute:route params:nil delegate:self];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    if (![self.sync verifyResponse:response]) return;
    ASLogInfo(@"Deleting of object %@ successfuly completed", self.objectURI);
    ATSynchronizer *sync = self.resourceClient.sync;
    ATMetaContext *metaContext = sync.metaContext;
    [metaContext deleteObjectAtURI:self.objectURI];
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    NSLog(@"Load failed: %@", error);
}

@end
