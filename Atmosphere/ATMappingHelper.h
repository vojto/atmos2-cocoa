//
//  ATMappingHelper.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATMappingHelper : NSObject

/** Entities map dictionary. Key represents server entity name
 and value represents client entity name */
@property (nonatomic, retain) NSDictionary *entitiesMap;
@property (nonatomic, retain) NSDictionary *attributesMap;
@property (nonatomic, retain) NSDictionary *relationsMap;

#pragma mark - Loading maps
- (void)loadEntitiesMapFromResource:(NSString *)resourceName;
- (void)loadAttributesMapFromResource:(NSString *)resourceName;
- (void)loadRelationsMapFromResource:(NSString *)resourceName;
- (void)_loadResource:(NSString *)resourceName intoDictionary:(NSDictionary **)dict;

#pragma mark - Mapping
- (NSString *)localEntityNameFor:(NSString *)serverEntityName;
- (NSString *)serverEntityNameFor:(NSString *)localEntityName;
- (NSString *)serverEntityNameForAppObject:(NSManagedObject *)appObject;
- (NSString *)serverAttributeNameFor:(NSString *)localName entity:(NSEntityDescription *)entity;
- (NSString *)localAttributeNameFor:(NSString *)serverName entity:(NSEntityDescription *)entity;

#pragma mark - Relations
- (NSDictionary *)relationsForObject:(NSManagedObject *)appObject;
- (NSDictionary *)relationsForEntity:(NSEntityDescription *)entity;

@end
