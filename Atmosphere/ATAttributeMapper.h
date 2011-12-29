//
//  ATAttributeMapper.h
//  Atmosphere
//
//  Created by Vojto Rinik on 12/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ATMappingHelper.h"

/**
 * This class does nothing
 */
@interface ATAttributeMapper : NSObject

@property (assign) ATMappingHelper *mappingHelper;

#pragma mark - Lifecycle
- (id)initWithMappingHelper:(ATMappingHelper *)mappingHelper;

@end
