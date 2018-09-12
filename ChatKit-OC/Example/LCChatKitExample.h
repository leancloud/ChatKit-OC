//
//  LCChatKitExample.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@interface LCChatKitExample : NSObject

#pragma mark - SDK Life Control
#pragma mark - quick start 使用下面的函数即可完成从程序启动到登录再到登出的完整流程

/*!
 *  入口胶水函数：登入入口函数
 *
 *  用户登录时调用
 */
+ (void)invokeThisMethodAfterLoginSuccessWithClientId:(NSString *)clientId
                                              success:(LCCKVoidBlock)success
                                               failed:(LCCKErrorBlock)failed;
/*!
 *  入口胶水函数：登出入口函数
 *
 *  用户即将退出登录时调用
 */
+ (void)invokeThisMethodBeforeLogoutSuccess:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed;

#pragma mark - 以下是各个子功能的胶水函数
///=============================================================================
/// @name 以下是各个子功能的胶水函数
///=============================================================================

/*!
 *  初始化的示例代码
 */
- (void)exampleInit;

/*!
 *  打开某个会话，可以是群聊、也可以是单聊
 */
+ (void)exampleOpenConversationViewControllerWithConversaionId:(NSString *)conversationId
                                      fromNavigationController:
                                          (UINavigationController *)navigationController;
/*!
 *  打开单聊页面
 */
+ (void)exampleOpenConversationViewControllerWithPeerId:(NSString *)peerId
                               fromNavigationController:
                                   (UINavigationController *)navigationController;

+ (void)exampleChangeGroupAvatarURLsForConversationId:(NSString *)conversationId;

/*!
 * 拉群
 */
+ (void)exampleCreateGroupConversationFromViewController:(UIViewController *)viewController;

+ (void)signOutFromViewController:(UIViewController *)viewController;


@end
