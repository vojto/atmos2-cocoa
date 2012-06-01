//
//  NSString+ATAdditions.m
//  Atmosphere
//
//  Created by Rinik Vojto on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+ATAdditions.h"

@implementation NSString (ATAdditions)

- (NSString *)pluralizedString {
    NSString *string = self;
    if ([self hasSuffix:@"y"]) {
        string = [self stringByReplacingCharactersInRange:NSMakeRange([self length]-1, 1) withString:@"ies"];
    } else {
        string = [self stringByAppendingString:@"s"];
    }
    
    return string;
}

@end
