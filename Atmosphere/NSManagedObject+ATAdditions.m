//
//  NSManagedObject+ATURI.m
//  Edukit
//
//  Created by Vojto Rinik on 7/9/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import "NSManagedObject+ATAdditions.h"

@implementation NSManagedObject (NSManagedObject_ATAdditions)

- (NSString *) objectIDString {
    NSManagedObjectID *objectID = [self objectID];
    NSURL *objectURI = [objectID URIRepresentation];
    return [objectURI absoluteString];
}

- (NSString *)stringValueForKey:(NSString *)key {
    id value = [self valueForKey:key];
    if ([value isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate *)value;
        return [date description];
    } else {
        return (NSString *)value;
    }
}

- (void)setStringValue:(id)value forKey:(NSString *)key {
    NSEntityDescription *entity = [self entity];
    NSDictionary *attributes = [entity attributesByName];
    NSAttributeDescription *attribute = [attributes objectForKey:key];
    if (!attributes) return;
    NSAttributeType type = [attribute attributeType];
    
    if (type == NSDateAttributeType) {
        NSDate *date = [NSDate dateWithString:(NSString *)value];
        [self setValue:date forKey:key];
    } else {
        [self setValue:value forKey:key];
    }
    
}

@end
