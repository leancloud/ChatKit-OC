//
//  AVRole_Internal.h
//  paas
//
//  Created by Zhu Zeng on 3/13/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVRole.h"

@class AVACL;

@interface AVRole ()

@property (nonatomic, readwrite, strong) AVACL * acl;
@property (nonatomic, readwrite, strong) NSMutableDictionary * relationData;

+(instancetype)role;

+(NSString *)className;
+(NSString *)endPoint;

@end
