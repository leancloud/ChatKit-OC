//
//  LCIMSettingService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMSettingService.h"
#import "AVOSCloud/AVOSCloud.h"

static BOOL LCIMAllLogsEnabled;

@implementation LCIMSettingService

+ (void)setAllLogsEnabled:(BOOL)enabled {
    LCIMAllLogsEnabled = enabled;
#ifndef __OPTIMIZE__
    [AVOSCloud setAllLogsEnabled:YES];
#endif
}

+ (BOOL)allLogsEnabled {
    return LCIMAllLogsEnabled;
}

+ (NSString *)IMKitVersion {
    return @"1.0.0";
}

@end
