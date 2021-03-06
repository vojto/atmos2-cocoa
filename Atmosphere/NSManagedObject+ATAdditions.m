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

#import "NSManagedObject+ATAdditions.h"
#import "ATAppContext.h"

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
        NSDate *date = [self _dateFromString:(NSString *)value];
        NSLog(@"Resolved date: %@ -> %@", value, date);
        [self setValue:date forKey:key];
    } else if (type == NSInteger16AttributeType) {
        NSNumber *number = [NSNumber numberWithFloat:[value integerValue]];
        [self setValue:number forKey:key];
    } else if (type == NSFloatAttributeType) {
        NSNumber *number = [NSNumber numberWithFloat:[value floatValue]];
        [self setValue:number forKey:key];
    } else if (type == NSBooleanAttributeType) {
        NSNumber *number = [NSNumber numberWithBool:[value boolValue]];
        [self setValue:number forKey:key];
    } else {
        [self setValue:value forKey:key];
    }
}

- (NSDate *)_dateFromString:(NSString *)value {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    value = [value stringByReplacingOccurrencesOfString:@"Z" withString:@"+0000"];
    NSArray *formats = [NSArray arrayWithObjects:@"YYYY-MM-dd HH:mm:ss zzzz", @"YYYY-MM-dd'T'HH:mm:ss.SSSZZZ", nil];
    NSDate *date = nil;
    
    for (NSString *format in formats) {
        [formatter setDateFormat:format];
        date = [formatter dateFromString:value];
        if (date != nil) {
            NSLog(@"Matched format %@", format);
            break;
        }
    }
    
    [formatter release];
    return date;
}

@end
