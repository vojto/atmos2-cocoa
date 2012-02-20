//
//  ATMetaContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATSynchronizer.h"
#import "ATObject.h"

@class ATMetaObject;

@interface ATMetaContext : NSObject <NSCoding> {
    NSMutableDictionary *_objects;
}

+ (id)restore;
+ (NSString *)path;

#pragma mark - Saving
- (BOOL)save;


#pragma mark - Marking changes

- (void)markURIChanged:(ATObjectURI)uri;
- (ATMetaObject *)objectAtURI:(ATObjectURI)uri;
- (ATMetaObject *)ensureObjectAtURI:(ATObjectURI)uri;
- (ATMetaObject *)createObjectAtURI:(ATObjectURI)uri;

#pragma mark - Finding objects

- (NSArray *)changedObjects;

@end
