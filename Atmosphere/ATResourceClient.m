//
//  ATResourceClient.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATSynchronizer.h"
#import "ATResourceClient.h"
#import "ATEntityFetchRequest.h"

@implementation ATResourceClient

@synthesize sync = _sync;
@synthesize client = _client;

#pragma mark - Lifecycle

- (id)initWithSynchronizer:(ATSynchronizer *)sync {
    if ((self = [super init])) {
        self.sync = sync;
        self.client = [RKClient clientWithBaseURL:@"http://localhost:3000/api"];
        NSLog(@"Created client: %@", self.client);
        [self.client.HTTPHeaders setObject:@"a0b48ccc3e747caf3ed77d94c8f3efc8b7911019" forKey:@"Atmosphere-Auth-Key"];
    }
    
    return self;
}

- (void)dealloc {
    self.client = nil;
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

@end
