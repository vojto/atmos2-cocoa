/* Copyright (C) 2011 Vojtech Rinik
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

#import "ATMessage.h"
#import <SBJson/NSObject+SBJSON.h>

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
