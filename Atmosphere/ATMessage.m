//
//  ATMessage.m
//  Edukit
//
//  Created by Vojto Rinik on 7/1/11.
//  Copyright 2011 CWL. All rights reserved.
//

#import "ATMessage.h"
#import "NSObject+JSON.h"

@implementation ATMessage

@synthesize type=_type, content=_content;

#pragma mark - Encoding/decoding

- (NSString *) JSONString {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:_type, @"type", _content, @"content", nil];
    return [dict JSONRepresentation];
}

+ (ATMessage *) messageFromJSONString:(NSString *)JSONString {
    NSDictionary *dict = [JSONString JSONValue];
    ATMessage *message = [[[ATMessage alloc] init] autorelease];
    message.type = [dict objectForKey:@"type"];
    message.content = [dict objectForKey:@"content"];
    return message;
}

#pragma mark - Description

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@: type: %@; content: %@>", [self class], _type, _content];
}

@end
