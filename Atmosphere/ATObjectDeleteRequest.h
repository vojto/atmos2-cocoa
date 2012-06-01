//
//  ATObjectDeleteRequest.h
//  Atmosphere
//
//  Created by Rinik Vojto on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

#import "ATObjectURI.h"

@class ATResourceClient;

@interface ATObjectDeleteRequest : NSObject <RKRequestDelegate>

@property (assign) ATResourceClient *resourceClient;
@property (assign) RKClient *networkClient;
@property (retain) ATObjectURI *objectURI;

- (id)initWithResourceClient:(ATResourceClient *)client objectURI:(ATObjectURI *)objectURI;
- (void)send;

@end
