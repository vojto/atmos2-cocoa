//
//  NSManagedObject+ATURI.h
//  Edukit
//
//  Created by Vojto Rinik on 7/9/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (NSManagedObject_ATAdditions)

- (NSString *) objectIDString;
- (NSString *)stringValueForKey:(NSString *)key;
- (void)setStringValue:(id)value forKey:(NSString *)key;

@end
