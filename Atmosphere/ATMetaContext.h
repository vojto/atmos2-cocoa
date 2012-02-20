//
//  ATMetaContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATSynchronizer.h"
#import "ATObject.h"

@interface ATMetaContext : NSObject {
    NSMutableDictionary *_data;
}

#pragma mark - Saving
- (BOOL)save;

#pragma mark - Marking changes

- (void)markURIChanged:(ATObjectURI)uri;

@end
