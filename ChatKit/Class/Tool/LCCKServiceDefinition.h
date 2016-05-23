//
//  LCCKServiceDefinition.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  All the Typedefine for all kinds of services.

#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKConstants.h"
#import "LCCKSingleton.h"
#import "LCCKMenuItem.h"

@class LCCKConversationViewController;
@class LCCKConversationListViewController;
@class LCCKMessage;
@import CoreLocation;

///---------------------------------------------------------------------
///---------------------LCCKSessionService------------------------------
///---------------------------------------------------------------------

@protocol LCCKSessionService <NSObject>

typedef void (^LCCKSessionNotOpenedHandler)(UIViewController *viewController, LCCKBooleanResultBlock callback);

@property (nonatomic, copy, readonly) NSString *clientId;
@property (nonatomic, copy, readonly) LCCKSessionNotOpenedHandler sessionNotOpenedHandler;

/*!
 * @param clientId The peer id in your peer system, LeanCloudChatKit will get the current user's information by both this id and the method `-[LCCKChatService getProfilesForUserIds:callback:]`.
 * @param callback Callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCCKBooleanResultBlock)callback;

/*!
 * @brief Close the client
 * @param callback Callback
 */
- (void)closeWithCallback:(LCCKBooleanResultBlock)callback;

- (void)setSessionNotOpenedHandler:(LCCKSessionNotOpenedHandler)sessionNotOpenedHandler;

@end

///--------------------------------------------------------------------
///----------------------LCCKUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKUserSystemService

@protocol LCCKUserSystemService <NSObject>

/*!
 *  @brief When fetching profiles completes, this callback will be invoked to notice LeanCloudChatKit
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason. 
 */
typedef void(^LCCKFetchProfilesCallBack)(NSArray<id<LCCKUserModelDelegate>> *users, NSError *error);

/*!
 *  @brief When LeanCloudChatKit wants to fetch profiles, this block will be invoked.
 *  @param userIds User ids
 *  @param callback When fetching profiles completes, this callback will be invoked on main thread to notice LeanCloudChatKit.
 */
typedef void(^LCCKFetchProfilesBlock)(NSArray<NSString *> *userIds, LCCKFetchProfilesCallBack callback);

@property (nonatomic, copy, readonly) LCCKFetchProfilesBlock fetchProfilesBlock;

/*!
 *  @brief Add the ablitity to fetch profiles.
 *  @attention  You must get peer information by peer id with a synchronous implementation.
 *              If implemeted, this block will be invoked automatically by LeanCloudChatKit for fetching peer profile.
 */
- (void)setFetchProfilesBlock:(LCCKFetchProfilesBlock)fetchProfilesBlock;

/*!
 * Remove all cached profiles.
 */
- (void)removeAllCachedProfiles;

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatorURL:(NSURL **)avatorURL error:(NSError * __autoreleasing *)error;
- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCCKUserResultCallBack)callback;

@end

///--------------------------------------------------------------------
///----------------------LCCKSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKSignatureService

@protocol LCCKSignatureService <NSObject>

/*!
 *  When fetching signature information completes, this callback will be invoked to notice LeanCloudChatKit.
 *  @attention If you fetch AVIMSignature fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCCKGenerateSignatureCallBack)(AVIMSignature *signature, NSError *error);

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
 *  @param callback - When fetching signature information complites, this callback will be invoked on main thread to notice LeanCloudChatKit.
 */
typedef void(^LCCKGenerateSignatureBlock)(NSString *clientId, NSString *conversationId, NSString *action, NSArray *clientIds, LCCKGenerateSignatureCallBack callback);

@property (nonatomic, copy, readonly) LCCKGenerateSignatureBlock generateSignatureBlock;

/*!
 * @brief Add the ablitity to pin signature to these actions: open, start(create conversation), kick, invite.
 * @attention  If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 */
- (void)setGenerateSignatureBlock:(LCCKGenerateSignatureBlock)generateSignatureBlock;

@end

///--------------------------------------------------------------------
///----------------------------LCCKUIService---------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKUIService

#import "LCCKServiceDefinition.h"

@protocol LCCKUIService <NSObject>

#pragma mark - - Open Profile

/*!
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
typedef void(^LCCKOpenProfileBlock)(NSString *userId, UIViewController *parentController);

@property (nonatomic, copy, readonly) LCCKOpenProfileBlock openProfileBlock;

/*!
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
- (void)setOpenProfileBlock:(LCCKOpenProfileBlock)openProfileBlock;

/*!
 *  当ChatKit需要预览图片消息时，会调用这个block
 *  @param index 用户点击的图片消息在imageMessages中的下标
 *  @param allVisibleImages 元素可能是图片，也可能是NSURL，以及混合。
 *  @param userInfo 用来传递上下文信息，例如，从某个Controller触发，或者从某个view触发等，键值在下面定义
 */
typedef void(^LCCKPreviewImageMessageBlock)(NSUInteger index, NSArray *allVisibleImages, NSArray *allVisibleThumbs, NSDictionary *userInfo);

@property (nonatomic, copy, readonly) LCCKPreviewImageMessageBlock previewImageMessageBlock;

/// 传递触发的UIViewController对象
#define LCCKPreviewImageMessageUserInfoKeyFromController    @"LCCKPreviewImageMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCCKPreviewImageMessageUserInfoKeyFromView          @"LCCKPreviewImageMessageUserInfoKeyFromView"

/*!
 *  当ChatKit需要预览图片消息时，会调用这个block.
 *  使用NSDictionary传递上下文信息，便于扩展
 */
- (void)setPreviewImageMessageBlock:(LCCKPreviewImageMessageBlock)previewImageMessageBlock;

/*!
 *  当ChatKit需要预览地理位置消息时，会调用这个block
 *  @param location 地理位置坐标
 *  @param geolocations 地理位置的文字描述
 *  @param userInfo 用来传递上下文信息，例如，从某个Controller触发，或者从某个view触发等，键值在下面定义
 */
typedef void(^LCCKPreviewLocationMessageBlock)(CLLocation *location, NSString *geolocations, NSDictionary *userInfo);

@property (nonatomic, copy, readonly) LCCKPreviewLocationMessageBlock previewLocationMessageBlock;

/// 传递触发的UIViewController对象
#define LCCKPreviewLocationMessageUserInfoKeyFromController    @"LCCKPreviewLocationMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCCKPreviewLocationMessageUserInfoKeyFromView          @"LCCKPreviewLocationMessageUserInfoKeyFromView"

/*!
 *  当ChatKit需要预览地理位置消息时，会调用这个block.
 *  使用NSDictionary传递上下文信息，便于扩展
 */
- (void)setPreviewLocationMessageBlock:(LCCKPreviewLocationMessageBlock)previewLocationMessageBlock;

/*!
 *  ChatKit会在长按消息时，调用这个block
 *  @param message 被长按的消息
 *  @param userInfo 用来传递上下文信息，例如，从某个Controller触发，或者从某个view触发等，键值在下面定义
 */
typedef NSArray<LCCKMenuItem *> *(^LCCKLongPressMessageBlock)(LCCKMessage *message, NSDictionary *userInfo);

@property (nonatomic, copy, readonly) LCCKLongPressMessageBlock longPressMessageBlock;

/// 传递触发的UIViewController对象
#define LCCKLongPressMessageUserInfoKeyFromController    @"LCCKLongPressMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCCKLongPressMessageUserInfoKeyFromView          @"LCCKLongPressMessageUserInfoKeyFromView"

/*!
 *  ChatKit会在长按消息时，调用这个block
 *  使用NSDictionary传递上下文信息，便于扩展
 */
- (void)setLongPressMessageBlock:(LCCKLongPressMessageBlock)longPressMessageBlock;

/**
 *  当IMUIKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
typedef void(^LCCKShowNotificationBlock)(UIViewController *viewController, NSString *title, NSString *subtitle, LCCKMessageNotificationType type);

@property (nonatomic, copy, readonly) LCCKShowNotificationBlock showNotificationBlock;

/**
 *  当IMUIKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
- (void)setShowNotificationBlock:(LCCKShowNotificationBlock)showNotificationBlock;

typedef CGFloat (^LCCKAvatarImageViewCornerRadiusBlock)(CGSize avatarImageViewSize);

@property (nonatomic, assign, readonly) LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock;

/*!
 *  设置会话列表和聊天界面头像ImageView的圆角弧度
 *  注意，请在需要圆角矩形时设置，会话列表和聊天界面头像默认圆形。
 */
- (void)setAvatarImageViewCornerRadiusBlock:(LCCKAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock;

@end

///---------------------------------------------------------------------
///------------------LCCKSettingService---------------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKSettingService

@protocol LCCKSettingService <NSObject>

/*!
 * You should always use like this, never forgive to cancel log before publishing.
 
 ```
 #ifndef __OPTIMIZE__
 [[LCChatKit sharedInstance] setAllLogsEnabled:YES];
 #endif
 ```
 
 */
+ (void)setAllLogsEnabled:(BOOL)enabled;
+ (BOOL)allLogsEnabled;
+ (NSString *)ChatKitVersion;
- (void)syncBadge;

/*!
 *  是否使用开发证书去推送，默认为 NO。如果设为 YES 的话每条消息会带上这个参数，云代码利用 Hook 设置证书
 *  参考 https://github.com/leancloud/leanchat-cloudcode/blob/master/cloud/mchat.js
 */
@property (nonatomic, assign) BOOL useDevPushCerticate;

@end

///---------------------------------------------------------------------
///---------------------LCCKConversationService-------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKConversationService

typedef void (^LCCKConversationResultBlock)(AVIMConversation *conversation, NSError *error);

@protocol LCCKConversationService <NSObject>

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

/**
 *  增加未读数
 *  @param conversation 相应对话
 */
- (void)increaseUnreadCountWithConversation:(AVIMConversation *)conversation;

/**
 *  最近对话列表左滑删除本地数据库的对话，将不显示在列表
 *  @param conversation
 */
- (void)deleteRecentConversation:(AVIMConversation *)conversation;

/**
 *  清空未读数
 *  @param conversation 相应的对话
 */
- (void)updateUnreadCountToZeroWithConversation:(AVIMConversation *)conversation;
/**
 *  删除全部缓存，比如当切换用户时，如果同一个人显示的名称和头像需要变更
 */
- (void)removeAllCachedRecentConversations;

@end

///---------------------------------------------------------------------
///---------------------LCCKConversationsListService--------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCCKConversationsListService

@protocol LCCKConversationsListService <NSObject>

/*!
 *  选中某个会话后的回调
 *  @param conversation 被选中的会话
 */
typedef void(^LCCKConversationsListDidSelectItemBlock)(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller);

/*!
 *  选中某个会话后的回调
 */
@property (nonatomic, copy, readonly) LCCKConversationsListDidSelectItemBlock didSelectItemBlock;

/*!
 *  设置选中某个会话后的回调
 */
- (void)setDidSelectItemBlock:(LCCKConversationsListDidSelectItemBlock)didSelectItemBlock;

/*!
 *  删除某个会话后的回调
 *  @param conversation 被选中的会话
 */
typedef void(^LCCKConversationsListDidDeleteItemBlock)(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller);

/*!
 *  删除某个会话后的回调
 */
@property (nonatomic, copy, readonly) LCCKConversationsListDidDeleteItemBlock didDeleteItemBlock;

/*!
 *  设置删除某个会话后的回调
 */
- (void)setDidDeleteItemBlock:(LCCKConversationsListDidDeleteItemBlock)didDeleteItemBlock;

/*!
 *  会话左滑菜单设置block
 *  @return  需要显示的菜单数组
 *  @param conversation, 会话
 *  @param editActions, 默认的菜单数组，成员为 UITableViewRowAction 类型
 */
typedef NSArray *(^LCCKConversationEditActionsBlock)(NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions, AVIMConversation *conversation, LCCKConversationListViewController *controller);

/*!
 *  可以通过这个block设置会话列表中每个会话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
@property (nonatomic, copy, readonly) LCCKConversationEditActionsBlock conversationEditActionBlock;

/*!
 *  设置会话列表中每个会话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
- (void)setConversationEditActionBlock:(LCCKConversationEditActionsBlock)conversationEditActionBlock;

typedef void(^LCCKMarkBadgeWithTotalUnreadCountBlock)(NSInteger totalUnreadCount, UIViewController *controller);

@property (nonatomic, copy, readonly) LCCKMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock;

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCCKMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock;

@end

//TODO:CacheService;