//
//  ATMetaContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATSynchronizer.h"
#import "ATObject.h"

@interface ATMetaContext : NSObject <NSCoding> {
    NSMutableDictionary *_objects;
}

+ (id)restore;
+ (NSString *)path;

#pragma mark - Saving
- (BOOL)save;


#pragma mark - Marking changes

- (void)markURIChanged:(ATObjectURI)uri;
- (NSDictionary *)objectAtURI:(ATObjectURI)uri;
- (NSDictionary *)ensureObjectAtURI:(ATObjectURI)uri;

@end
