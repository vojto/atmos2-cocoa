//
//  ATMappingHelper.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ATMappingHelper : NSObject {
    NSDictionary *_entitiesMap;
    NSDictionary *_attributesMap;
}

/** Entities map dictionary. Key represents server entity name
 and value represents client entity name */
@property (nonatomic, retain) NSDictionary *entitiesMap;
@property (nonatomic, retain) NSDictionary *attributesMap;

#pragma mark - Loading maps
- (void)loadEntitiesMapFromResource:(NSString *)resourceName;
- (void)loadAttributesMapFromResource:(NSString *)resourceName;

#pragma mark - Mapping
- (NSString *)localEntityNameFor:(NSString *)serverEntityName;
- (NSString *)serverEntityNameFor:(NSString *)localEntityName;
- (NSString *)serverEntityNameForAppObject:(NSManagedObject *)appObject;
- (NSString *)serverAttributeNameFor:(NSString *)localName entity:(NSEntityDescription *)entity;
- (NSString *)localAttributeNameFor:(NSString *)serverName entity:(NSEntityDescription *)entity;


@end
