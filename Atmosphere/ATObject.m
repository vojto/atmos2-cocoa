//
//  ATObject.m
//  Edukit
//
//  Created by Vojto Rinik on 7/5/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import "ATObject.h"
#import "NSManagedObject+ATAdditions.h"

@implementation ATObject

@dynamic ATID;
@dynamic clientURI;
@dynamic isChanged;
@dynamic isMarkedDeleted;
@synthesize isLocked;

- (void)awakeFromFetch {
    self.isLocked = NO;
}

- (void) setClientObject:(NSManagedObject *)object {
    self.clientURI = [object objectIDString];
}

- (NSManagedObject *) clientObjectInContext:(NSManagedObjectContext *)context {
    if (self.clientURI == nil) return nil;
    NSError *error = nil;
    NSURL *URI = [NSURL URLWithString:self.clientURI];
    NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:URI];
    NSManagedObject *object = [context existingObjectWithID:objectID error:&error];
    if (error != nil) {
        RKLog(@"Client object lookup: %@", error);
    }
    return object;
}

- (void) markChanged {
    self.isChanged = [NSNumber numberWithBool:YES];
}

- (void) markSynchronized {
    self.isChanged = [NSNumber numberWithBool:NO];
}

- (void)markDeleted {
    self.isMarkedDeleted = [NSNumber numberWithBool:YES];
}

- (void)lock {
    self.isLocked = YES;
}

- (void)unlock {
    self.isLocked = NO;
}

@end
