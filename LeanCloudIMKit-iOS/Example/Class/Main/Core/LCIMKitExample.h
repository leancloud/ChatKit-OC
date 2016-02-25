//
//  LCIMKitExample.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/2/24.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMKit.h"

@interface LCIMKitExample : NSObject

+ (instancetype)sharedInstance;

@property (strong, nonatomic, readwrite) LCIMKit *IMKit;

#pragma mark - SDK Life Control
#pragma mark - quick start 使用下面三个函数即可完成从程序启动到登录再到登出的完整流程

/// ----------------------------------------------------------------------------------------------------------
///---注意：在`-[AppDelegate didFinishLaunchingWithOptions:]` 等函数中调用下面这几个基础的入口胶水函数，可完成初步的集成。
///
///---注意：进一步地，胶水代码中包含了特地设置的#warning，请仔细阅读这些warning的注释，根据实际情况调整代码，以符合你的需求。
/// ----------------------------------------------------------------------------------------------------------

/*!
 *  入口胶水函数：初始化入口函数
 *
 *  程序完成启动，在appdelegate中的 `-[AppDelegate didFinishLaunchingWithOptions:]` 一开始的地方调用.
 */
- (void)invokeThisMethodInDidFinishLaunching;
- (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/*!
 *  入口胶水函数：登入入口函数
 *
 *  用户即将退出登录时调用
 */
- (void)invokeThisMethodAfterLoginSuccess;
/*!
 *  入口胶水函数：登出入口函数
 *
 *  用户即将退出登录时调用
 */
- (void)invokeThisMethodBeforeLogout;

/// ------------------------------------------------------------------------------------------------
///------------------------------- 以下是各个子功能的胶水函数--------------------------------------------
/// ----------------------------------------------------------------------------------------------------------

#pragma mark - basic

/**
 *  初始化的示例代码
 */
- (BOOL)exampleInit;


/**
 *  登录的示例代码
 */
- (void)exampleLoginWithUserID:(NSString *)aUserID password:(NSString *)aPassword successBlock:(void(^)())aSuccessBlock failedBlock:(void(^)(NSError *aError))aFailedBlock;

/**
 *  监听连接状态
 */
- (void)exampleListenConnectionStatus;

/**
 *  注销的示例代码
 */
- (void)exampleLogout;

/**
 *  设置头像显示方式：包括圆角弧度和contentMode
 */
- (void)exampleSetAvatarStyle;

/**
 *  创建会话列表页面
 */
//- (LCIMConversationListViewController *)exampleMakeConversationListControllerWithSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)aSelectItemBlock;

/**
 *  打开某个会话
 */
//- (void)exampleOpenConversationViewControllerWithConversation:(LCIMConversation *)aConversation fromNavigationController:(UINavigationController *)aNavigationController;

/**
 *  打开单聊页面
 */
//- (void)exampleOpenConversationViewControllerWithPerson:(LCIMPerson *)aPerson fromNavigationController:(UINavigationController *)aNavigationController;

/**
 *  打开群聊页面
 */
//- (void)exampleOpenConversationViewControllerWithTribe:(LCIMTribe *)aTribe fromNavigationController:(UINavigationController *)aNavigationController;

#pragma mark - 自定义业务

/**
 *  设置如何显示自定义消息
 */
//- (void)exampleShowCustomMessageWithConversationController:(LCIMConversationViewController *)aConversationController;

/**
 *  设置气泡最大宽度
 */
- (void)exampleSetMaxBubbleWidth;

/**
 * 头像点击事件
 */
- (void)exampleListenOnClickAvatar;


@end
