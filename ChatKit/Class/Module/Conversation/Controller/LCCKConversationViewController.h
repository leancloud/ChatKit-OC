//
//  LCCKConversationViewController.h
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//
@import UIKit;
@class AVIMConversation;

#import "LCCKChat.h"
#import "LCCKBaseConversationViewController.h"

typedef void (^LCCKConversationHandler) (AVIMConversation *conversation, LCCKConversationViewController *conversationController);

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

///---------------------------------------------------------------------------------------------
///---- Initialize a unique single chat type object of LCCKConversationViewController ----------
///---------------------------------------------------------------------------------------------

/*!
 * @param PeerId id of the peer, a unique single conversation should be initialized with this property.
 * @attention `peerId` can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCCKConversationViewController is initialized with this method, the property named `conversationId` will be set automatically.
 *            The `conversaionId` will be unique, meaning that if the conversation between the current user id and the `peerId` has already existed,
 *            LeanCloudChatKit will reuse the conversation instead of creating a new one.
 * @return Initialized unique single chat type object of LCCKConversationViewController
 */
- (instancetype)initWithPeerId:(NSString *)peerId;

///----------------------------------------------------------------------------------------------
///---- Initialize a single or group chat type object of LCCKConversationViewController ---------
///----------------------------------------------------------------------------------------------

/*!
 * @param conversationId Id of the conversation, group conversation should be initialized with this property.
 * @attention ConversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCCKConversationViewController is initialized with this method, the property named `peerId` will be nil.
 *            conversationId 与 peerId 并不等同。您一般不能自己构造一个conversationId，而是从 conversation 等特定接口中才能读取到 conversationId。如果需要使用 personId 来打开对话，应该使用 `-initWithPeerId:` 这个接口。
 * @return Initialized single or group chat type odject of LCCKConversationViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

/*!
 *  是否禁用文字的双击放大功能，默认为NO
 */
@property (nonatomic, assign) BOOL disableTextShowInFullScreen;

/*!
 * 设置获取 AVIMConversation 对象结束后的 Handler。 这里可以做异常处理，比如获取失败等操作。
 * 获取失败时，LCCKConversationHandler 返回值中的AVIMConversation 为 nil，成功时为正确的 conversation 值。
 */
- (void)setConversationHandler:(LCCKConversationHandler)conversationHandler;

/*!
 * 设置获取历史纪录结束时的 Handler。 这里可以做异常处理，比如获取失败等操作。
 * 获取失败时，LCCKViewControllerBooleanResultBlock 返回值中的 error 不为 nil，包含错误原因，成功时 succeeded 值为 YES。
 */
- (void)setLoadHistoryMessagesHandler:(LCCKViewControllerBooleanResultBlock)loadHistoryMessagesHandler;

@end


