//
//  AVGeoPoint_Internal.h
//  paas
//
//  Created by Zhu Zeng on 3/12/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVGeoPoint.h"

@interface AVGeoPoint ()

+(NSDictionary *)dictionaryFromGeoPoint:(AVGeoPoint *)point;
+(AVGeoPoint *)geoPointFromDictionary:(NSDictionary *)dict;

@end
