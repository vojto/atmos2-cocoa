//
//  ATObjectURI.h
//  Atmosphere
//
//  Created by Rinik Vojto on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


@interface ATObjectURI : NSObject <NSCopying>

@property (retain, nonatomic) NSString *entity;
@property (retain, nonatomic) NSString *identifier;

+ (id)URIWithEntity:(NSString *)entity identifier:(NSString *)identifier;
- (id)initWithEntity:(NSString *)entity identifier:(NSString *)identifier;
+ (id)URIFromString:(NSString *)string;
- (id)initFromString:(NSString *)string;
- (NSString *)stringValue;

@end