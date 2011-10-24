//
//  ATMessage.h
//  Edukit
//
//  Created by Vojto Rinik on 7/1/11.
//  Copyright 2011 CWL. All rights reserved.
//


@interface ATMessage : NSObject {
    NSString *_type;
    NSDictionary *_content;
}


@property (retain, nonatomic) NSString *type;
@property (retain, nonatomic) NSDictionary *content;

- (NSString *) JSONString;
+ (ATMessage *) messageFromJSONString:(NSString *)JSONString;

@end
