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

#import <CoreData/CoreData.h>

@interface ATObject : NSManagedObject {
    BOOL isLocked;
}
    
@property (nonatomic, retain) NSString *ATID;
@property (nonatomic, retain) NSString *clientURI;
@property (nonatomic, retain) NSNumber *isChanged;
// isDeleted is used by NSManagedObject, ergo the crappy name.
@property (nonatomic, retain) NSNumber *isMarkedDeleted;
@property (assign) BOOL isLocked;

- (void) setClientObject:(NSManagedObject *)object;
- (NSManagedObject *) clientObjectInContext:(NSManagedObjectContext *)context;

- (void) markChanged;
- (void) markSynchronized;
- (void) markDeleted;

- (void)lock;
- (void)unlock;

@end
