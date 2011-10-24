//
//  RKLog.h
//  Edukit
//
//  Created by Vojto Rinik on 4/14/11.
//  Copyright 2011 CWL. All rights reserved.
//

#define RKLog(format, ...) NSLog(@"[%@] %@", [self class], [NSString stringWithFormat:format, ## __VA_ARGS__]);

#define RKAssertLog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]

#define RKAssert(condition, ...) do { if (!(condition)) { RKAssertLog(__VA_ARGS__); }} while(0)

#define RKPostNotification(name) [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:name object:nil]]
#define RKObserveNotification(notifName,sel) [[NSNotificationCenter defaultCenter] addObserver:self selector:sel name:notifName object:nil]

#define RKDefaults [NSUserDefaults standardUserDefaults]