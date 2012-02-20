//
//  ATObjectURI.m
//  Atmosphere
//
//  Created by Rinik Vojto on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ATObjectURI.h"

ATObjectURI ATObjectURIMake(NSString *entity, NSString *identifier) {
    ATObjectURI uri;
    uri.entity = entity;
    uri.identifier = identifier;
    return uri;
}

NSString* ATObjectURIToString(ATObjectURI uri) {
    RKAssert(uri.entity, @"URI is missing entity, can't convert to string!");
    RKAssert(uri.identifier, @"URI is missing identifier, can't convert to string!");
    return [NSString stringWithFormat:@"%@.%@", uri.entity, uri.identifier];
}