//
//  ATObjectSaveRequest.m
//  Atmosphere
//
//  Created by Rinik Vojto on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RNUtil.h"
#import "ATObjectSaveRequest.h"
#import "ATResourceClient.h"
#import "ATAppContext.h"
#import "ATMetaContext.h"

@implementation ATObjectSaveRequest

@synthesize resourceClient = _resourceClient, networkClient = _networkClient, options = _options, object = _object;

- (id)initWithResourceClient:(ATResourceClient *)client object:(NSManagedObject *)object options:(NSDictionary *)options {
    if ((self = [super init])) {
        self.resourceClient = client;
        self.networkClient  = client.client;
        self.object         = object;
        self.options        = options;
    }
    
    return self;
}

- (void)send {
    ATAppContext *appContext = self.resourceClient.sync.appContext; // TODO: Refactor to something nicer
    
    // Options
    NSString *wrapper           = RKTry(self.object, paramWrapper);
    NSDictionary *routeParams   = RKTry(self.object, routeParams);
    
    NSString *action    = [self.options objectForKey:@"action"];
    if (!action) action = ATActionCreate;
    ATRoute route       = [self.resourceClient routeForEntity:self.object.entity.name action:action params:routeParams];
    
    NSDictionary *data = [appContext dataForObject:self.object];

    NSDictionary *params;
    if (wrapper) params = [NSDictionary dictionaryWithObject:data forKey:wrapper];
    else         params = data;
    
    ASLogInfo(@"Sending save request (%@): %@", action, data);
    [self.resourceClient loadRoute:route params:params delegate:self];
    
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    // TODO: Refactor the code in a way that will let us remove this reference to meta context.
    // We'll just want to call methods on synchronizer to alter meta context.
    ATSynchronizer *sync = self.resourceClient.sync;
    ATMetaContext *metaContext = sync.metaContext;
    ATAppContext *appContext = sync.appContext;
    
    ATObjectURI *uri = [appContext URIOfAppObject:self.object];
    NSError *error = nil;
    
    if ([response statusCode] != 200) {
        ASLogWarning(@"[ATObjectSaveRequest] Failed: %d (%@)", [response statusCode], [response bodyAsString]);
        return;
    }
    
    NSDictionary *data = [response parsedBody:&error];
    if (error != nil) {
        ASLogWarning(@"[ATObjectSaveRequest] Can't parse the response (%@)", [response bodyAsString]);
        return;
    }
    
    ASLogInfo(@"Object save request completed: %@", data);
    // 01 Change ID if needed
    NSString *IDField = self.resourceClient.IDField;
    NSString *ID = [data objectForKey:IDField];
    if (!ID) {
        ASLogError(@"[ATObjectSaveRequest] No ID find in the response! (IDField = %@, response = %@)", IDField, data);
    }
    ATObjectURI *changedURI = [uri copy];
    changedURI.identifier = ID;
    [sync changeURIFrom:uri to:changedURI];

    // 02 Update the data
    [sync updateObjectAtURI:changedURI withDictionary:data];
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    NSLog(@"Load failed: %@", error);
}

@end
