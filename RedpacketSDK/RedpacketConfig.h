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
/**
 *  注册红包配置项
 */
- (void)config;
/**
 *  获取当前红包用户
 */
- (RedpacketUserInfo *)redpacketUserInfo;
/**
 *  设置消息体拦截
 */
- (void)lcck_setting;

@end
