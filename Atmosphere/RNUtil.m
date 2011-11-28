//
//  RNUtil.m
//  RNUtil
//
//  Created by Vojto Rinik on 11/19/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//#import "RNUtil.h"
//#import "ASLogger.h"

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

@end
