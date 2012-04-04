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

#import "RNUtil.h"
#import "ASLogger.h"

@implementation RNUtil

+ (void)initLoggingInDirectory:(NSString *)logDirectory {
    NSString *timestamp = [[NSDate date] descriptionWithCalendarFormat:@"%Y-%m-%d %H%M%S" timeZone:nil locale:nil];
    NSString *logName = [NSString stringWithFormat:@"%@.log", timestamp];
    NSString *logFile = [logDirectory stringByAppendingPathComponent:logName];
    [@"" writeToFile:logFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    ;
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
    [[ASLogger defaultLogger] setName:appName facility:@"RINIK" options:0];
    [[ASLogger defaultLogger] addLogFile:logFile];
    ASLogInfo(@"Initialized logging for bundle %@", appName);
}

+ (void)initLogging {
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
    [[ASLogger defaultLogger] setName:appName facility:@"RINIK" options:0];
    asl_add_log_file([[ASLogger defaultLogger] client], 0);
}

+ (NSString *)uuidString {
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString *uuidString = [(NSString*)CFUUIDCreateString(nil, uuid) autorelease];
    CFRelease(uuid);
    return [uuidString lowercaseString];
}

+ (NSString *)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
	NSString *path = [basePath stringByAppendingPathComponent:appName];
	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:path]) {
	} else {
		[manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	return path;
}

@end
