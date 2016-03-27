//
//  LCIMServiceDefinition.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  All the Typedefine for all kinds of services.

#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMConstants.h"
@class LCIMConversationViewController;
@class LCIMConversationListViewController;
@class LCIMMessage;

///---------------------------------------------------------------------
///---------------------LCIMSessionService------------------------------
///---------------------------------------------------------------------

@protocol LCIMSessionService <NSObject>

@property (nonatomic, copy, readonly) NSString *clientId;

/*!
 * @param clientId The peer id in your peer system, LeanCloudIMKit will get the current user's information by both this id and the method `-[LCIMChatService getProfilesForUserIds:callback:]`.
 * @param callback Callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback;

/*!
 * @brief Close the client
 * @param callback Callback
 */
- (void)closeWithCallback:(LCIMBooleanResultBlock)callback;

@end

///--------------------------------------------------------------------
///----------------------LCIMUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUserSystemService

@protocol LCIMUserSystemService <NSObject>

/*!
 *  @brief When fetching profiles completes, this callback will be invoked to notice LeanCloudIMKit
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason. 
 */
typedef void(^LCIMFetchProfilesCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);

/*!
 *  @brief When LeanCloudIMKit wants to fetch profiles, this block will be invoked.
 *  @param userIds User ids
 *  @param callback When fetching profiles completes, this callback will be invoked on main thread to notice LeanCloudIMKit.
 */
typedef void(^LCIMFetchProfilesBlock)(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback);

@property (nonatomic, copy, readonly) LCIMFetchProfilesBlock fetchProfilesBlock;

/*!
 *  @brief Add the ablitity to fetch profiles.
 *  @attention  You could get peer information by peer id with either a synchronous or an asynchronous implementation.
 *              If implemeted, this block will be invoked automatically by LeanCloudIMKit for fetching peer profile.
 */
- (void)setFetchProfilesBlock:(LCIMFetchProfilesBlock)fetchProfilesBlock;

/*!
 * Remove all cached profiles.
 */
- (void)removeAllCachedProfiles;

@end

///--------------------------------------------------------------------
///----------------------LCIMSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSignatureService

@protocol LCIMSignatureService <NSObject>

/*!
 *  When fetching signature information completes, this callback will be invoked to notice LeanCloudIMKit.
 *  @attention If you fetch AVIMSignature fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCIMGenerateSignatureCallBack)(AVIMSignature *signature, NSError *error);

/*!
 *  @brief If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 *  @param clientId - Id of operation initiator
 *  @param conversationId －  Id of target conversation
 *  @param action － Kinds of action:
                    "open": log in an account
                    "start": create a conversation
                    "add": invite myself or others to the conversation
                    "remove": kick someone out the conversation
 *  @param clientIds － Target id list for the action
 *  @param callback - When fetching signature information complites, this callback will be invoked on main thread to notice LeanCloudIMKit.
 */
typedef void(^LCIMGenerateSignatureBlock)(NSString *clientId, NSString *conversationId, NSString *action, NSArray *clientIds, LCIMGenerateSignatureCallBack callback);

@property (nonatomic, copy, readonly) LCIMGenerateSignatureBlock generateSignatureBlock;

/*!
 * @brief Add the ablitity to pin signature to these actions: open, start(create conversation), kick, invite.
 * @attention  If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 */
- (void)setGenerateSignatureBlock:(LCIMGenerateSignatureBlock)generateSignatureBlock;

@end

///--------------------------------------------------------------------
///----------------------------LCIMUIService---------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUIService

#import "LCIMServiceDefinition.h"

@protocol LCIMUIService <NSObject>

#pragma mark - - Open Profile

/*!
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
typedef void(^LCIMOpenProfileBlock)(NSString *userId, UIViewController *parentController);

@property (nonatomic, copy, readonly) LCIMOpenProfileBlock openProfileBlock;

/*!
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock;

/*!
 *  当IMKit需要预览图片消息时，会调用这个block
 *  @param index 用户点击的图片消息在imageMessages中的下标
 *  @param imageMessagesInfo 元素可能是图片，也可能是NSURL，以及混合。
 *  @param userInfo 用来传递上下文信息，例如，从某个Controller触发，或者从某个view触发等，键值在下面定义
 */
typedef void(^LCIMPreviewImageMessageBlock)(NSUInteger index, NSArray *imageMessagesInfo, NSDictionary *userInfo);

@property (nonatomic, copy, readonly) LCIMPreviewImageMessageBlock previewImageMessageBlock;

/// 传递触发的UIViewController对象
#define LCIMPreviewImageMessageUserInfoKeyFromController    @"LCIMPreviewImageMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCIMPreviewImageMessageUserInfoKeyFromView          @"LCIMPreviewImageMessageUserInfoKeyFromView"

/*!
 *  当IMKit需要预览图片消息时，会调用这个block.
 *  使用NSDictionary传递上下文信息，便于扩展
 */
- (void)setPreviewImageMessageBlock:(LCIMPreviewImageMessageBlock)previewImageMessageBlock;

/**
 *  当IMUIKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
typedef void(^LCIMShowNotificationBlock)(UIViewController *viewController, NSString *title, NSString *subtitle, LCIMMessageNotificationType type);

@property (nonatomic, copy, readonly) LCIMShowNotificationBlock showNotificationBlock;

/**
 *  当IMUIKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
- (void)setShowNotificationBlock:(LCIMShowNotificationBlock)showNotificationBlock;

@end

///---------------------------------------------------------------------
///------------------LCIMSettingService---------------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSettingService

@protocol LCIMSettingService <NSObject>

/*!
 * You should always use like this, never forgive to cancel log before publishing.
 
 ```
 #ifndef __OPTIMIZE__
 [[LCIMKit sharedInstance] setAllLogsEnabled:YES];
 #endif
 ```
 
 */
+ (void)setAllLogsEnabled:(BOOL)enabled;
+ (BOOL)allLogsEnabled;
+ (NSString *)IMKitVersion;
- (void)syncBadge;

/*!
 *  是否使用开发证书去推送，默认为 NO。如果设为 YES 的话每条消息会带上这个参数，云代码利用 Hook 设置证书
 *  参考 https://github.com/leancloud/leanchat-cloudcode/blob/master/cloud/mchat.js
 */
@property (nonatomic, assign) BOOL useDevPushCerticate;

@end

///---------------------------------------------------------------------
///---------------------LCIMConversationService-------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMConversationService

typedef void (^LCIMConversationResultBlock)(AVIMConversation *conversation, NSError *error);

@protocol LCIMConversationService <NSObject>

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

/*!
 *  通过会话Id构建聊天页面
 *  @param conversationId 会话Id
 *  @return 聊天页面
 */
- (LCIMConversationViewController *)createConversationViewControllerWithConversationId:(NSString *)conversationId;

/*!
 *  构建单聊页面
 *  @param peedId 聊天对象
 */
- (LCIMConversationViewController *)createConversationViewControllerWithPeerId:(NSString *)peerId;

/*!
 *  创建会话列表页面
 *  @return 所创建的会话列表页面
 */
- (LCIMConversationListViewController *)createConversationListViewController;

@end

///---------------------------------------------------------------------
///---------------------LCIMConversationsListService--------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMConversationsListService

@protocol LCIMConversationsListService <NSObject>

/*!
 *  选中某个会话后的回调
 *  @param conversation 被选中的会话
 */
typedef void(^LCIMConversationsListDidSelectItemBlock)(AVIMConversation *conversation);

/*!
 *  选中某个会话后的回调
 */
@property (nonatomic, copy, readonly) LCIMConversationsListDidSelectItemBlock didSelectItemBlock;

/*!
 *  设置选中某个会话后的回调
 */
- (void)setDidSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)didSelectItemBlock;

/*!
 *  删除某个会话后的回调
 *  @param conversation 被选中的会话
 */
typedef void(^LCIMConversationsListDidDeleteItemBlock)(AVIMConversation *conversation);

/*!
 *  删除某个会话后的回调
 */
@property (nonatomic, copy, readonly) LCIMConversationsListDidDeleteItemBlock didDeleteItemBlock;

/*!
 *  设置删除某个会话后的回调
 */
- (void)setDidDeleteItemBlock:(LCIMConversationsListDidDeleteItemBlock)didDeleteItemBlock;

/*!
 *  会话左滑菜单设置block
 *  @return  需要显示的菜单数组
 *  @param conversation, 会话
 *  @param editActions, 默认的菜单数组，成员为 UITableViewRowAction 类型
 */
typedef NSArray *(^LCIMConversationEditActionsBlock)(NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions);

/*!
 *  可以通过这个block设置会话列表中每个会话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
@property (nonatomic, copy, readonly) LCIMConversationEditActionsBlock conversationEditActionBlock;

/*!
 *  设置会话列表中每个会话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
- (void)setConversationEditActionBlock:(LCIMConversationEditActionsBlock)conversationEditActionBlock;

@end

//TODO:CacheService;