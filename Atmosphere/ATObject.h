//
//  ATObject.h
//  Edukit
//
//  Created by Vojto Rinik on 7/5/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ATObject : NSManagedObject
    
@property (nonatomic, retain) NSString *ATID;
@property (nonatomic, retain) NSString *clientURI;
@property (nonatomic, retain) NSNumber *isChanged;
// isDeleted is used by NSManagedObject, ergo the crappy name.
@property (nonatomic, retain) NSNumber *isMarkedDeleted;

- (void) setClientObject:(NSManagedObject *)object;
- (NSManagedObject *) clientObjectInContext:(NSManagedObjectContext *)context;

- (void) markChanged;
- (void) markSynchronized;
- (void) markDeleted;

@end
