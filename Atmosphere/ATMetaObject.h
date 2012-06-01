//
//  ATMetaObject.h
//  Atmosphere
//
//  Created by Rinik Vojto on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATObjectURI.h"

@interface ATMetaObject : NSObject <NSCoding> {
@private
    
}

@property ATObjectURI *uri;
@property BOOL isChanged;
@property BOOL isLocalOnly;

- (id)initWithURI:(ATObjectURI *)uri;

@end