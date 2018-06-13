//
//  LCCKConversationViewController.h
//  LCCKChatBarExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

@class AVIMConversation;

#import "LCCKChat.h"
#import "LCCKBaseConversationViewController.h"

FOUNDATION_EXTERN NSString *const LCCKConversationViewControllerErrorDomain;

@interface LCCKConversationViewController : LCCKBaseConversationViewController <LCCKChatMessageCellDelegate>

/*!
 *  @brief Id of the single or group conversation, group conversation should be initialized with this property.
 *  @details Initialization method is `-initWithConversationId:`.
 */
@property (nonatomic, copy, readonly) NSString *conversationId;

/*!
 *  @brief Id of the peer, single conversation should be initialized with this property.
 *  @details Initialization method is `-initWithPeerId:`.
 */
@property (nonatomic, copy, readonly) NSString *peerId;

#pragma mark - Initialize a unique single chat type object of LCCKConversationViewController
///=============================================================================
/// @name Initialize a unique single chat type object of LCCKConversationViewController
///=============================================================================

/*!
 * @param PeerId id of the peer, a unique single conversation should be initialized with this property.
 * @attention `peerId` can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCCKConversationViewController is initialized with this method, the property named `conversationId` will be set automatically.
 *            The `conversaionId` will be unique, meaning that if the conversation between the current user id and the `peerId` has already existed,
 *            LeanCloudChatKit will reuse the conversation instead of creating a new one.
 * @return Initialized unique single chat type object of LCCKConversationViewController
 */
- (instancetype)initWithPeerId:(NSString *)peerId;

#pragma mark - Initialize a single or group chat type object of LCCKConversationViewController
///=============================================================================
/// @name Initialize a single or group chat type object of LCCKConversationViewController
///=============================================================================

/*!
 * @param conversationId Id of the conversation, group conversation should be initialized with this property.
 * @attention ConversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCCKConversationViewController is initialized with this method, the property named `peerId` will be nil.
 *            conversationId 与 peerId 并不等同。您一般不能自己构造一个 conversationId，而是从 conversation 等特定接口中才能读取到 conversationId。如果需要使用 personId 来打开对话，应该使用 `-initWithPeerId:` 这个接口。
 * @return Initialized single or group chat type odject of LCCKConversationViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

/*!
 * 如果不在对话中，是否自动加入对话，默认为 NO.
 * @attention 仅适用于使用 ConversationId 初始化。
 */
@property (nonatomic, assign, getter=isEnableAutoJoin) BOOL enableAutoJoin;

@property (nonatomic, assign, getter=isAvailable, readonly) BOOL available;

/*!
 * If `isAvailable` is NO, it will return nil
 */
- (AVIMConversation *)getConversationIfExists;

#pragma mark - send Message
///=============================================================================
/// @name send Message
///=============================================================================

/*!
 *  文本发送
 * @attention 发送前必须检查 `isAvailable` 属性是否为YES
 */
- (void)sendTextMessage:(NSString *)text;

/*
 * 图片发送 包含图片上传交互
 * 默认图片压缩比0.6，如想自定义压缩比，请使用 `-sendImageMessageData` 方法
 *
 * @param image, 要发送的图片
 * @attention Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched
 *            发送前必须检查 `isAvailable` 属性是否为YES, 确保发送行为是在 conversation 被 fetch 之后进行的。
 */
- (void)sendImageMessage:(UIImage *)image;

- (void)sendImageMessageData:(NSData *)imageData;

/*!
 * 语音发送
 * @attention Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched
 *            发送前必须检查 `isAvailable` 属性是否为YES, 确保发送行为是在 conversation 被 fetch 之后进行的。
 */
- (void)sendVoiceMessageWithPath:(NSString *)voicePath time:(NSTimeInterval)recordingSeconds;

/*!
 * 地理位置发送
 * @attention Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched
 *            发送前必须检查 `isAvailable` 属性是否为YES, 确保发送行为是在 conversation 被 fetch 之后进行的。
 */
- (void)sendLocationMessageWithLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate locatioTitle:(NSString *)locationTitle;

/*!
 * 本地消息，仅仅在本地展示，不会发送到服务端
 */
- (void)sendLocalFeedbackTextMessge:(NSString *)localFeedbackTextMessge;

/*!
 * 自定义消息位置发送
 * @attention Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched
 *            发送前必须检查 `isAvailable` 属性是否为YES, 确保发送行为是在 conversation 被 fetch 之后进行的。
 */
- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage;

/*!
 * 自定义消息位置发送
 * @attention 自定义消息暂时支持失败消息本地缓存
 * @attention Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched
 *            发送前必须检查 `isAvailable` 属性是否为YES, 确保发送行为是在 conversation 被 fetch 之后进行的。
 */
- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage
            progressBlock:(AVProgressBlock)progressBlock
                  success:(LCCKBooleanResultBlock)success
                   failed:(LCCKBooleanResultBlock)failed;

//TODO:
/*!
 * 发送用户的当前输入状态
 */
//- (void)sendInputStatus:(LCCKConversationInputStatus)status;

/*!
 *  是否禁用文字的双击放大功能，默认为 NO
 */
@property (nonatomic, assign) BOOL disableTextShowInFullScreen;

/*!
 * 是否禁用标题自动配置
 * 默认配置如下：
 *          - 最右侧显示静音状态
 *          - 单聊默认显示对方昵称，群聊显示 `conversation` 的 name 字段值
 */
@property (nonatomic, assign, getter=isDisableTitleAutoConfig) BOOL disableTitleAutoConfig;

#pragma mark - Handler
///=============================================================================
/// @name Handler
///=============================================================================

/*!
 * 设置获取 AVIMConversation 对象结束后的 Handler。 这里可以做异常处理，比如获取失败等操作。
 * 获取失败时，LCCKConversationHandler 返回值中的AVIMConversation 为 nil，成功时为正确的 conversation 值。
 * @attention 执行优先级高于 LCChatKit 类中的同名方法，如果在 LCChatKit 中设置过同名方法，就可以不设置本类中的该方法。
 */
- (void)setFetchConversationHandler:(LCCKFetchConversationHandler)fetchConversationHandler;

/*!
 * 设置获取历史纪录结束时的 Handler。 这里可以做异常处理，比如获取失败等操作。
 * 获取失败时，LCCKViewControllerBooleanResultBlock 返回值中的 error 不为 nil，包含错误原因，成功时 succeeded 值为 YES。
 * @attention 执行优先级高于 LCChatKit 类中的同名方法，如果在 LCChatKit 中设置过同名方法，就可以不设置本类中的该方法。
 */
- (void)setLoadLatestMessagesHandler:(LCCKLoadLatestMessagesHandler)loadLatestMessagesHandler;

@end


