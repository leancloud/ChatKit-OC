//
//  LCCKSettingService.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for common chat setting.

#import <Foundation/Foundation.h>
#import "LCCKServiceDefinition.h"
#import <AVOSCloud/AVOSCloud.h>
@class AVIMVideoMessage;
/*!
 * LCCKSettingService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCCKSettingServiceErrorDomain;

@interface LCCKSettingService : LCCKSingleton <LCCKSettingService>

//TODO:
/*!
 * 1. 设置离线推送
 * 2. 设置未读消息
 * 3. 推送相关设置
 * 4. Others
 */

/**
 *  图片消息，临时的压缩图片路径
 *  @return
 */
- (NSString *)tmpPath;

/**
 *  根据消息的 id 获取声音文件的路径
 *  @param objectId 消息的 id
 *  @return 文件路径
 */
- (NSString *)getPathByObjectId:(NSString *)objectId;

/*!
 *  根据消息来获取视频文件的路径。
 */
- (NSString *)videoPathOfMessage:(AVIMVideoMessage *)message;

// please call in application:didFinishLaunchingWithOptions:launchOptions
- (void)registerForRemoteNotification;

// push message
- (void)pushMessage:(NSString *)message userIds:(NSArray *)userIds block:(LCCKBooleanResultBlock)block;

// please call in applicationDidBecomeActive:application
- (void)cleanBadge;

//save the local applicationIconBadgeNumber to the server
- (void)syncBadge;

@end
