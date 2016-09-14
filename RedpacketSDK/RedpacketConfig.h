//
//  RedpacketConfig.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YZHRedpacketBridgeProtocol.h"

@interface RedpacketConfig : NSObject <YZHRedpacketBridgeDataSource>

+ (instancetype)sharedConfig;
- (void)config;

- (RedpacketUserInfo *)redpacketUserInfo;
- (void)lcck_setting;
@end
