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

#import "ASLogger.h"

#define RKLog(format, ...) NSLog(@"[%@] %@", [self class], [NSString stringWithFormat:format, ## __VA_ARGS__]);

#define RKAssertLog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]

#define RKAssert(condition, ...) do { if (!(condition)) { RKAssertLog(__VA_ARGS__); }} while(0)

#define RKPostNotification(name) [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:name object:nil]]
#define RKObserveNotification(notifName,sel) [[NSNotificationCenter defaultCenter] addObserver:self selector:sel name:notifName object:nil]

#define RKDefaults [NSUserDefaults standardUserDefaults]

#import <Foundation/Foundation.h>


@interface RNUtil : NSObject

+ (void)initLoggingInDirectory:(NSString *)logDirectory;
+ (void)initLogging;
+ (NSString *)uuidString;
+ (NSString *)applicationSupportDirectory;

@end
