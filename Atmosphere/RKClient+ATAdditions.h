//
//  RKClient+ATAdditions.h
//  Atmosphere
//
//  Created by Rinik Vojto on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>

// This interface adds load: method to RKClient
// The method is implemented in the RKClient, but for some reason it's made private.

// This interface will make the method public.

@interface RKClient(ATAdditions)

- (RKRequest*)load:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate;

@end