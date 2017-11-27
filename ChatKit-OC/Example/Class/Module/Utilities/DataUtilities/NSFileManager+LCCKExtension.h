//
//  LCCKContactListViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSFileManager+Paths.h"

@interface NSFileManager (LCCKExtension_)

/**
 *  图片 — 设置
 */
+ (NSString *)lcck_pathUserSettingImage:(NSString *)imageName userId:(NSString *)userId;

/**
 *  图片 — 聊天
 */
+ (NSString *)lcck_pathUserChatImage:(NSString*)imageName userId:(NSString *)userId;

/**
 *  图片 — 聊天背景
 */
+ (NSString *)lcck_pathUserChatBackgroundImage:(NSString *)imageName userId:(NSString *)userId;

/**
 *  图片 — 用户头像
 */
+ (NSString *)lcck_pathUserAvatar:(NSString *)imageName userId:(NSString *)userId;

/**
 *  图片 — 屏幕截图
 */
+ (NSString *)lcck_pathScreenshotImage:(NSString *)imageName;

/**
 *  图片 — 本地通讯录
 */
+ (NSString *)lcck_pathContactsAvatar:(NSString *)imageName userId:(NSString *)userId;

/**
 *  聊天语音
 */
+ (NSString *)lcck_pathUserChatVoice:(NSString *)voiceName userId:(NSString *)userId;

/**
 *  表情
 */
+ (NSString *)lcck_pathExpressionForGroupID:(NSString *)groupID;

/**
 *  数据 — 本地通讯录
 */
+ (NSString *)lcck_pathContactsData;

/**
 *  数据库 — 通用
 */
+ (NSString *)lcck_pathDBCommonForUserId:(NSString *)userId;;

/**
 *  数据库 — 聊天
 */
+ (NSString *)lcck_pathDBMessageForUserId:(NSString *)userId;;

/**
 *  缓存
 */
+ (NSString *)lcck_cacheForFile:(NSString *)filename;


@end
