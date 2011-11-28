/* Copyright (C) 2011 Vojtech Rinik
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

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
