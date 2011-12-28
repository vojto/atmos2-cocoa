//
//  ATMetaContext.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATMetaContext : NSObject {
    NSInteger _version;
}

#pragma mark - Managing version number

- (void)readVersionFromDefaults;
- (void)writeVersionToDefaults;
- (void)updateVersion:(NSInteger)version;

- (NSNumber *)versionAsNumber;

@end
