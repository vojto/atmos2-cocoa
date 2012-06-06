//
//  ATAuthentication.m
//  Atmosphere
//
//  Created by Rinik Vojto on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "RNUtil.h"
#import "ATSynchronizer.h"
#import "ATAuthentication.h"

NSString * const kATAuthChangedNotification = @"ATAuthChangedNotification";

NSString * const kATAuthTokenDefaultsKey = @"ATAuthToken";
NSString * const kATCurrentUserDefaultsKey = @"ATCurrentUser";

@implementation ATAuthentication

@synthesize sync = _sync, resourceClient = _resourceClient;
@synthesize authToken = _authToken, currentUser = _currentUser;


- (id)initWithSynchronizer:(ATSynchronizer *)sync {
    if ((self = [super init])) {
        self.sync = sync;
        [self performSelector:@selector(_restoreToken) withObject:nil afterDelay:0];
    }
    
    return self;
}

/*****************************************************************************/
#pragma mark - Authentication
/*****************************************************************************/

- (BOOL)isLoggedIn {
    return !!self.authToken;
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
    NSString *path = [NSString stringWithFormat:@"/login?username=%@&password=%@", username, password];
    [self.resourceClient loadPath:path callback:^(RKResponse *response) {
        if (response.statusCode == 200) {
            NSDictionary *data = [response parsedBody:nil];
            NSString *token = [data objectForKey:@"token"];
            self.authToken = token;
            self.currentUser = data;
            [self _rememberToken];
            [self _useToken];
            ASLogInfo(@"Logged in as %@ (%@)", username, token);
            RKPostNotification(kATAuthChangedNotification);
            [self.sync startSync];
        } else {
            ASLogWarning(@"Failed to login as %@", username);
            RKPostNotification(kATAuthChangedNotification);
        }
    }];
}

- (void)_rememberToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.authToken forKey:kATAuthTokenDefaultsKey];
    [defaults setObject:self.currentUser forKey:kATCurrentUserDefaultsKey];
}

- (void)_restoreToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.authToken = [defaults objectForKey:kATAuthTokenDefaultsKey];
    self.currentUser = [defaults objectForKey:kATCurrentUserDefaultsKey];
    [self _useToken];
    RKPostNotification(kATAuthChangedNotification);
}

- (void)_useToken {
    if (self.authToken) {
        [self.resourceClient addHeader:@"Auth-Token" withValue:self.authToken];
    } else {
        [self.resourceClient removeHeader:@"Auth-Token"];
    }
}

- (void)logout {
    self.authToken = nil;
    self.currentUser = nil;
    [self _useToken];
    RKPostNotification(kATAuthChangedNotification);
}

- (void)signupWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password {
    RKRequest *request = [self.resourceClient prepareRequest:@"/sign_up"];
    request.method = RKRequestMethodPOST;
    request.params = [NSDictionary dictionaryWithObjectsAndKeys:username, @"username",
                                                                email, @"email",
                                                                password, @"password", nil];
    request.onDidLoadResponse = ^(RKResponse *response) {
        NSLog(@"Sign up completed: %@ %@", response.bodyAsString, [response parsedBody:nil]);
    };
    [request send];
}

/*****************************************************************************/
#pragma mark - Handling errors
/*****************************************************************************/

- (void)handleIllegalResponse:(RKResponse *)response {
    if (response.statusCode == 401) {
        [self logout];
    }
}

@end
