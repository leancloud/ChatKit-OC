//
//  LCCKServiceDefinition.h
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  All the Typedefine for all kinds of services.

#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKConstants.h"
#import "LCCKSingleton.h"
#import "LCCKMenuItem.h"
@class AVIMClient;
@class AVIMConversation;
@class AVIMSignature;

@class LCCKConversationViewController;
@class LCCKConversationListViewController;
@class LCCKMessage;
@import CoreLocation;

#pragma mark - LCCKSessionService
///=============================================================================
/// @name LCCKSessionService
///=============================================================================

@protocol LCCKSessionService <NSObject>

typedef void (^LCCKReconnectSessionCompletionHandler)(BOOL succeeded, NSError *error);

/*!
 * @param granted granted fore single signOn
 * 默认允许重连，error的code为4111时，需要额外请求权限，才可标记为YES。
 */
typedef void (^LCCKForceReconnectSessionBlock)(NSError *error, BOOL granted, __kindof UIViewController *viewController, LCCKReconnectSessionCompletionHandler completionHandler);

@property (nonatomic, copy, readonly) NSString *clientId;
@property (nonatomic, strong, readonly) AVIMClient *client;
@property (nonatomic, assign) BOOL disableSingleSignOn;
@property (nonatomic, copy, readonly) LCCKForceReconnectSessionBlock forceReconnectSessionBlock;

/*!
 * @param clientId You can use the user id in your user system as clientId, ChatKit will get the current user's information by both this id and the method `-[LCCKChatService getProfilesForUserIds:callback:]`.
 * @param callback Callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCCKBooleanResultBlock)callback;

/*!
 * @param force Just for Single Sign On
 */
- (void)openWithClientId:(NSString *)clientId force:(BOOL)force callback:(AVIMBooleanResultBlock)callback;
/*!
 * @brief Close the client
 * @param callback Callback
 */
- (void)closeWithCallback:(LCCKBooleanResultBlock)callback;

/*!
 * set how you want to force reconnect session. It is usually usefully for losing session because of single sign-on, or weak network.
 */
- (void)setForceReconnectSessionBlock:(LCCKForceReconnectSessionBlock)forceReconnectSessionBlock;

@end

#pragma mark - LCCKUserSystemService
///=============================================================================
/// @name LCCKUserSystemService
///=============================================================================

@protocol LCCKUserSystemService <NSObject>

/*!
 *  @brief The block to execute with the users' information for the userIds. Always execute this block at some point when fetching profiles completes on main thread. Specify users' information how you want ChatKit to show.
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCCKFetchProfilesCompletionHandler)(NSArray<id<LCCKUserDelegate>> *users, NSError *error);

/*!
 *  @brief When LeanCloudChatKit wants to fetch profiles, this block will be invoked.
 *  @param userIds User ids
 *  @param completionHandler The block to execute with the users' information for the userIds. Always execute this block at some point during your implementation of this method on main thread. Specify users' information how you want ChatKit to show.
 */
typedef void(^LCCKFetchProfilesBlock)(NSArray<NSString *> *userIds, LCCKFetchProfilesCompletionHandler completionHandler);

@property (nonatomic, copy) LCCKFetchProfilesBlock fetchProfilesBlock;

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

/**
 *  remove person profile cache
 *
 *  @param person id
 */
- (void)removeCachedProfileForPeerId:(NSString *)peerId;

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatarURL:(NSURL **)avatarURL error:(NSError * __autoreleasing *)error;
- (NSArray<id<LCCKUserDelegate>> *)getCachedProfilesIfExists:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)error;

/*!
 * 如果从缓存查询到的userids数量不相符，则返回nil
 */
- (NSArray<id<LCCKUserDelegate>> *)getCachedProfilesIfExists:(NSArray<NSString *> *)userIds shouldSameCount:(BOOL)shouldSameCount error:(NSError * __autoreleasing *)theError;
- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCCKUserResultCallBack)callback;
- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCCKUserResultsCallBack)callback;
- (NSArray<id<LCCKUserDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)error;

@end

#pragma mark - LCCKSignatureService
///=============================================================================
/// @name LCCKSignatureService
///=============================================================================

@protocol LCCKSignatureService <NSObject>

/*!
 *  @brief The block to execute with the signature information for session. Always execute this block at some point when fetching signature information completes on main thread. Specify signature information how you want ChatKit pin to these actions: open, start(create conversation), kick, invite.
 *  @attention If you fetch AVIMSignature fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCCKGenerateSignatureCompletionHandler)(AVIMSignature *signature, NSError *error);

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
 *  @param completionHandler The block to execute with the signature information for session. Always execute this block at some point during your implementation of this method on main thread. Specify signature information how you want ChatKit pin to these actions: open, start(create conversation), kick, invite.
 */
typedef void(^LCCKGenerateSignatureBlock)(NSString *clientId, NSString *conversationId, NSString *action, NSArray *clientIds, LCCKGenerateSignatureCompletionHandler completionHandler);

@property (nonatomic, copy) LCCKGenerateSignatureBlock generateSignatureBlock;

/*!
 * @brief Add the ablitity to pin signature to these actions: open, start(create conversation), kick, invite.
 * @attention  If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 */
- (void)setGenerateSignatureBlock:(LCCKGenerateSignatureBlock)generateSignatureBlock;

@end

#pragma mark - LCCKUIService
///=============================================================================
/// @name LCCKUIService
///=============================================================================

#import "LCCKServiceDefinition.h"

@protocol LCCKUIService <NSObject>

/// 传递触发的UIViewController对象
#define LCCKPreviewImageMessageUserInfoKeyFromController    @"LCCKPreviewImageMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCCKPreviewImageMessageUserInfoKeyFromView          @"LCCKPreviewImageMessageUserInfoKeyFromView"
/// 传递触发的UIView对象
#define LCCKPreviewImageMessageUserInfoKeyFromPlaceholderView          @"LCCKPreviewImageMessageUserInfoKeyFromPlaceholderView"

/*!
 *  打开某个profile的回调block
 *  @param userId 被点击的user 的 userId (clientId) ，与 user 属性中 clientId 的区别在于，本属性永远不为空，但 user可能为空。
 *  @param parentController 用于打开的顶层控制器
 */
typedef void(^LCCKOpenProfileBlock)(NSString *userId, id<LCCKUserDelegate> user, __kindof UIViewController *parentController);

@property (nonatomic, copy) LCCKOpenProfileBlock openProfileBlock;

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

@property (nonatomic, copy) LCCKPreviewImageMessageBlock previewImageMessageBlock;

/// 传递触发的UIViewController对象
#define LCCKPreviewImageMessageUserInfoKeyFromController    @"LCCKPreviewImageMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCCKPreviewImageMessageUserInfoKeyFromView          @"LCCKPreviewImageMessageUserInfoKeyFromView"
/// 传递触发的UIView对象
#define LCCKPreviewImageMessageUserInfoKeyFromPlaceholderView          @"LCCKPreviewImageMessageUserInfoKeyFromPlaceholderView"

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

@property (nonatomic, copy) LCCKPreviewLocationMessageBlock previewLocationMessageBlock;

/// 传递触发的UIViewController对象
#define LCCKPreviewLocationMessageUserInfoKeyFromController    @"LCCKPreviewLocationMessageUserInfoKeyFromController"
/// 传递触发的UIView对象
#define LCCKPreviewLocationMessageUserInfoKeyFromView          @"LCCKPreviewLocationMessageUserInfoKeyFromView"

/*!
 *  当ChatKit需要预览地理位置消息时，会调用这个block.
 *  使用NSDictionary传递上下文信息，便于扩展
 */
- (void)setPreviewLocationMessageBlock:(LCCKPreviewLocationMessageBlock)previewLocationMessageBlock;

//TODO:可自定义长按能响应的消息类型
/*!
 *  ChatKit会在长按消息时，调用这个block
 *  @param message 被长按的消息
 *  @param userInfo 用来传递上下文信息，例如，从某个Controller触发，或者从某个view触发等，键值在下面定义
 */
typedef NSArray<LCCKMenuItem *> *(^LCCKLongPressMessageBlock)(LCCKMessage *message, NSDictionary *userInfo);

@property (nonatomic, copy) LCCKLongPressMessageBlock longPressMessageBlock;

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
 *  当ChatKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
typedef void(^LCCKShowNotificationBlock)(__kindof UIViewController *viewController, NSString *title, NSString *subtitle, LCCKMessageNotificationType type);

@property (nonatomic, copy) LCCKShowNotificationBlock showNotificationBlock;

/**
 *  当ChatKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
- (void)setShowNotificationBlock:(LCCKShowNotificationBlock)showNotificationBlock;

/**
 *  当ChatKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param type 类型
 */

typedef void(^LCCKHUDActionBlock)(__kindof UIViewController *viewController, UIView *view, NSString *title, LCCKMessageHUDActionType type);

@property (nonatomic, copy) LCCKHUDActionBlock HUDActionBlock;

/**
 *  当ChatKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
- (void)setHUDActionBlock:(LCCKHUDActionBlock)HUDActionBlock;

typedef CGFloat (^LCCKAvatarImageViewCornerRadiusBlock)(CGSize avatarImageViewSize);

@property (nonatomic, assign) LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock;

/*!
 *  设置对话列表和聊天界面头像ImageView的圆角弧度
 *  注意，请在需要圆角矩形时设置，对话列表和聊天界面头像默认圆形。
 */
- (void)setAvatarImageViewCornerRadiusBlock:(LCCKAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock;

@end

#pragma mark - LCCKSettingService
///=============================================================================
/// @name LCCKSettingService
///=============================================================================

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
- (void)setCurrentConversationBackgroundImage:(UIImage *)image scaledToSize:(CGSize)scaledToSize;
- (void)setBackgroundImage:(UIImage *)image forConversationId:(NSString *)conversationId scaledToSize:(CGSize)scaledToSize;

@end

#pragma mark - LCCKConversationService
///=============================================================================
/// @name LCCKConversationService
///=============================================================================

typedef void (^LCCKConversationResultBlock)(AVIMConversation *conversation, NSError *error);
typedef void (^LCCKFetchConversationHandler) (AVIMConversation *conversation, LCCKConversationViewController *conversationController);
typedef void (^LCCKConversationInvalidedHandler) (NSString *conversationId, LCCKConversationViewController *conversationController, id<LCCKUserDelegate> administrator, NSError *error);

@protocol LCCKConversationService <NSObject>

@property (nonatomic, copy) LCCKFetchConversationHandler fetchConversationHandler;

/*!
 * 设置获取 AVIMConversation 对象结束后的 Handler。 这里可以做异常处理，比如获取失败等操作。
 * 获取失败时，LCCKConversationHandler 返回值中的AVIMConversation 为 nil，成功时为正确的 conversation 值。
 */
- (void)setFetchConversationHandler:(LCCKFetchConversationHandler)fetchConversationHandler;

@property (nonatomic, copy) LCCKConversationInvalidedHandler conversationInvalidedHandler;

/*!
 *  会话失效的处理 block，如当群被解散或当前用户不再属于该会话时，对应会话会失效应当被删除并且关闭聊天窗口
 */
- (void)setConversationInvalidedHandler:(LCCKConversationInvalidedHandler)conversationInvalidedHandler;

typedef void (^LCCKFilterMessagesCompletionHandler)(NSArray *filterMessages, NSError *error);
typedef void (^LCCKFilterMessagesBlock)(AVIMConversation *conversation, NSArray<AVIMTypedMessage *> *messages, LCCKFilterMessagesCompletionHandler completionHandler);

/*!
 * 用于筛选消息，比如：群定向消息、筛选黑名单消息、黑名单消息
 * @attention 同步方法异步方法皆可
 */
- (void)setFilterMessagesBlock:(LCCKFilterMessagesBlock)filterMessagesBlock;

@property (nonatomic, copy) LCCKFilterMessagesBlock filterMessagesBlock;

//TODO:未实现
typedef void (^LCCKLoadLatestMessagesHandler)(LCCKConversationViewController *conversationController, BOOL succeeded, NSError *error);

@property (nonatomic, copy) LCCKLoadLatestMessagesHandler loadLatestMessagesHandler;

/*!
 * 设置获取历史纪录结束时的 Handler。 这里可以做异常处理，比如获取失败等操作。
 * 获取失败时，LCCKViewControllerBooleanResultBlock 返回值中的 error 不为 nil，包含错误原因，成功时 succeeded 值为 YES。
 */
- (void)setLoadLatestMessagesHandler:(LCCKLoadLatestMessagesHandler)loadLatestMessagesHandler;

- (void)createConversationWithMembers:(NSArray *)members type:(LCCKConversationType)type unique:(BOOL)unique callback:(AVIMConversationResultBlock)callback;

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

/**
 *  增加未读数
 *  @param conversation 相应对话
 */
- (void)increaseUnreadCountWithConversationId:(NSString *)conversationId;
- (void)increaseUnreadCountWithConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;
/**
 *  最近对话列表左滑删除本地数据库的对话，将不显示在列表
 *  @param conversation
 */
- (void)deleteRecentConversationWithConversationId:(NSString *)conversationId;
- (void)deleteRecentConversationWithConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;

/**
 *  清空未读数
 *  @param conversation 相应的对话
 */
- (void)updateUnreadCountToZeroWithConversationId:(NSString *)conversationId;
- (void)updateUnreadCountToZeroWithConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;
/**
 *  删除全部缓存，比如当切换用户时，如果同一个人显示的名称和头像需要变更
 */
- (BOOL)removeAllCachedRecentConversations;

- (void)sendWelcomeMessageToPeerId:(NSString *)peerId text:(NSString *)text block:(LCCKBooleanResultBlock)block;
- (void)sendWelcomeMessageToConversationId:(NSString *)conversationId text:(NSString *)text block:(LCCKBooleanResultBlock)block;

@end

#pragma mark - LCCKConversationsListService
///=============================================================================
/// @name LCCKConversationsListService
///=============================================================================

@protocol LCCKConversationsListService <NSObject>

/*!
 *  选中某个对话后的回调
 *  @param conversation 被选中的对话
 */
typedef void(^LCCKDidSelectConversationsListCellBlock)(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller);

/*!
 *  选中某个对话后的回调
 */
@property (nonatomic, copy) LCCKDidSelectConversationsListCellBlock didSelectConversationsListCellBlock;

/*!
 *  设置选中某个对话后的回调
 */
- (void)setDidSelectConversationsListCellBlock:(LCCKDidSelectConversationsListCellBlock)didSelectConversationsListCellBlock;

/*!
 *  删除某个对话后的回调
 *  @param conversation 被选中的对话
 */
typedef void(^LCCKDidDeleteConversationsListCellBlock)(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller);

/*!
 *  删除某个对话后的回调
 */
@property (nonatomic, copy) LCCKDidDeleteConversationsListCellBlock didDeleteConversationsListCellBlock;

/*!
 *  设置删除某个对话后的回调
 */
- (void)setDidDeleteConversationsListCellBlock:(LCCKDidDeleteConversationsListCellBlock)didDeleteConversationsListCellBlock;

/*!
 *  对话左滑菜单设置block
 *  @return  需要显示的菜单数组
 *  @param conversation, 对话
 *  @param editActions, 默认的菜单数组，成员为 UITableViewRowAction 类型
 */
typedef NSArray *(^LCCKConversationEditActionsBlock)(NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions, AVIMConversation *conversation, LCCKConversationListViewController *controller);

/*!
 *  可以通过这个block设置对话列表中每个对话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
@property (nonatomic, copy) LCCKConversationEditActionsBlock conversationEditActionBlock;

/*!
 *  设置对话列表中每个对话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
- (void)setConversationEditActionBlock:(LCCKConversationEditActionsBlock)conversationEditActionBlock;

typedef void(^LCCKMarkBadgeWithTotalUnreadCountBlock)(NSInteger totalUnreadCount, __kindof UIViewController *controller);

@property (nonatomic, copy) LCCKMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock;

/*!
 * 如果不是TabBar样式，请实现该Blcok。如果不实现，默认会把 App 当作是 TabBar 样式，修改 navigationController 的 tabBarItem 的 badgeValue 数字显示，数字超出99显示省略号。
 */
- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCCKMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock;

@end

//TODO:CacheService;