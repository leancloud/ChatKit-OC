//
//  AVRelation_Internal.h
//  paas
//
//  Created by Zhu Zeng on 3/8/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVRelation.h"

@interface AVRelation ()

@property (nonatomic, readwrite, copy) NSString * key;
@property (nonatomic, readwrite, weak) AVObject * parent;

+(AVRelation *)relationFromDictionary:(NSDictionary *)dict;

@end
