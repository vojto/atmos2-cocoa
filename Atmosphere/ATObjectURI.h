//
//  ATObjectURI.h
//  Atmosphere
//
//  Created by Rinik Vojto on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

typedef struct _ATObjectURI {
    NSString *entity;
    NSString *identifier;
} ATObjectURI;

ATObjectURI ATObjectURIMake(NSString *entity, NSString *identifier);

NSString* ATObjectURIToString(ATObjectURI uri);
ATObjectURI ATObjectURIFromString(NSString *string);