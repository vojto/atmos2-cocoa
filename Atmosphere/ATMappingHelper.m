//
//  ATMappingHelper.m
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ATMappingHelper.h"

@implementation ATMappingHelper

@synthesize entitiesMap=_entitiesMap, attributesMap=_attributesMap, relationsMap=_relationsMap;

#pragma mark - Loading maps

- (void)loadEntitiesMapFromResource:(NSString *)resourceName {
    [self _loadResource:resourceName intoDictionary:&_entitiesMap];
}

- (void)loadAttributesMapFromResource:(NSString *)resourceName {
    [self _loadResource:resourceName intoDictionary:&_attributesMap];
}

- (void)loadRelationsMapFromResource:(NSString *)resourceName {
    [self _loadResource:resourceName intoDictionary:&_relationsMap];
}

- (void)_loadResource:(NSString *)resourceName intoDictionary:(NSDictionary **)dict {
    *dict = ([NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:resourceName ofType:@"plist"]]);
    [(*dict) retain];
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

#pragma mark - Relations

- (NSDictionary *)relationsForObject:(NSManagedObject *)appObject {
    return [self relationsForEntity:appObject.entity];
}

- (NSDictionary *)relationsForEntity:(NSEntityDescription *)entity {
    return [self.relationsMap objectForKey:entity.name];
}

- (NSString *)serverRelationNameFor:(NSString *)relation entity:(NSEntityDescription *)entity {
    NSDictionary *relations = [self relationsForEntity:entity];
    NSString *key = [[relations allKeysForObject:relation] lastObject];
    if (!key) key = [NSString stringWithFormat:@"%@_id", [relation lowercaseString]];
    return key;
}

@end
