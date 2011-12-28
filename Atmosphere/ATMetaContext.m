//
//  ATMetaContext.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATMetaContext.h"

NSString * const ATVersionDefaultsKey = @"ATVersion";

@implementation ATMetaContext

#pragma mark - Managing version number

- (void)readVersionFromDefaults {
    _version = [(NSNumber *)[[NSUserDefaults standardUserDefaults] valueForKey:ATVersionDefaultsKey] intValue];
}

- (void)writeVersionToDefaults {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:_version] forKey:ATVersionDefaultsKey];
}

- (void)updateVersion:(NSInteger)version
{
    if (version > _version) {
        _version = version;
        [self writeVersionToDefaults];
    }
}

- (NSNumber *)versionAsNumber {
    return [NSNumber numberWithLong:_version];
}

@end
