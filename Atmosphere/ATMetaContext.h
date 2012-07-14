//
//  ATMetaContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATSynchronizer.h"

@class ATMetaObject;

@interface ATMetaContext : NSObject <NSCoding> {
    NSMutableDictionary *_objects;
}

+ (id)restore;
+ (NSString *)path;

#pragma mark - Saving
- (BOOL)save;
- (void)_saveImmediately;

#pragma mark - Marking changes
- (void)markURIChanged:(ATObjectURI *)uri;
- (void)markURISynced:(ATObjectURI *)uri;
- (void)markURIDeleted:(ATObjectURI *)uri;

#pragma mark - Finding objects

- (ATMetaObject *)objectAtURI:(ATObjectURI *)uri;
- (ATMetaObject *)ensureObjectAtURI:(ATObjectURI *)uri;
- (ATMetaObject *)createObjectAtURI:(ATObjectURI *)uri;
- (NSArray *)allObjects;
- (NSArray *)changedObjects;

#pragma mark - Other tasks
- (void)changeIDTo:(NSString *)newID atURI:(ATObjectURI *)uri;
- (void)deleteObjectAtURI:(ATObjectURI *)uri;


@end
