//
//  ATMappingHelper.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATMappingHelper.h"

@implementation ATMappingHelper

@synthesize entitiesMap=_entitiesMap, attributesMap=_attributesMap;

#pragma mark - Loading maps

- (void)loadEntitiesMapFromResource:(NSString *)resourceName {
    self.entitiesMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"]];
}

- (void)loadAttributesMapFromResource:(NSString *)resourceName {
    self.attributesMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"]];
}

#pragma mark - Mapping

- (NSString *)localEntityNameFor:(NSString *)serverEntityName {
    NSString *name = [_entitiesMap objectForKey:serverEntityName];
    return name ? name : serverEntityName;
}

- (NSString *)serverEntityNameFor:(NSString *)localEntityName {
    for (NSString *serverName in [_entitiesMap allKeys]) {
        if ([localEntityName isEqualToString:[self localEntityNameFor:serverName]]) {
            return serverName;
        }
    }
    return localEntityName;
}

- (NSString *)serverEntityNameForAppObject:(NSManagedObject *)appObject {
    NSEntityDescription *entityDescription = [appObject entity];
    return [self serverEntityNameFor:[entityDescription name]];
}

- (NSString *)serverAttributeNameFor:(NSString *)localName entity:(NSEntityDescription *)entity {
    NSDictionary *map = [_attributesMap objectForKey:entity.name];
    
    for (NSString *serverName in [map allKeys]) {
        NSString *someLocalName = [map objectForKey:serverName];
        if ([someLocalName isEqualToString:localName])
            return serverName;
    }
    
    return localName;
}

- (NSString *)localAttributeNameFor:(NSString *)serverName entity:(NSEntityDescription *)entity {
    NSDictionary *map = [_attributesMap objectForKey:entity.name];
    NSString *localName = [map objectForKey:serverName];
    if (localName) {
        return localName;
    } else {
        return serverName;
    }
}

@end
