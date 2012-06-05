//
//  ATAuthentication.h
//  Atmosphere
//
//  Created by Rinik Vojto on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

@class ATSynchronizer;
@class ATResourceClient;

@interface ATAuthentication : NSObject

@property (assign) ATSynchronizer *sync;
@property (assign) ATResourceClient *resourceClient;

@property (nonatomic, retain) NSString *authToken;
@property (nonatomic, retain) NSDictionary *currentUser;

#pragma mark - Lifecycle
- (id)initWithSynchronizer:(ATSynchronizer *)sync;

#pragma mark - Authentication
- (BOOL)isLoggedIn;
/**
 Will make HTTP request to login, get the token, then it will set the token
 as header.
 
 This method is tailor-made for atmos2-server. Eventually it should be customizable,
 but when using custom API, developer might just implement custom authentication
 mechanizm. */
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;
- (void)_rememberToken;
- (void)_restoreToken;
- (void)_useToken;
- (void)logout;
- (void)signupWithUsername:(NSString *)username email:(NSString *)email password:(NSString *)password;

@end
