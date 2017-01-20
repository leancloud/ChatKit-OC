//
//  AVInstallation_Internal.h
//  LeanCloud
//
//  Created by Zhu Zeng on 3/27/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVInstallation.h"

@interface AVInstallation ()

@property (nonatomic, copy) NSString *timeZone;
@property (nonatomic, copy) NSString *deviceType;

+(AVQuery *)installationQuery;
+(AVInstallation *)installation;


+(NSString *)deviceType;

+(NSString *)className;
+(NSString *)endPoint;

@end
