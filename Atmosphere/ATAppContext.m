//
//  ATAppContext.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATAppContext.h"

@implementation ATAppContext

@synthesize managedContext=_managedContext;

#pragma mark - Core Data

- (BOOL)hasChanges {
    return [self.managedContext hasChanges];
}

- (void)save:(NSError **)error {
    [self.managedContext save:error];
}

- (void)obtainPermanentIDsForObjects:(NSArray *)objects error:(NSError **)error {
    [self.managedContext obtainPermanentIDsForObjects:objects error:error];
}

@end
