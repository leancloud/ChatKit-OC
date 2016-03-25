//
//  LCIMChatController.h
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCIMChat.h"
#import "LCIMBaseConversationViewController.h"

@interface LCIMChatController : LCIMBaseConversationViewController <LCIMChatMessageCellDelegate>

//@property (assign, nonatomic) LCIMMessageChat messageChatType;

//
//- (instancetype)initWithChatType:(LCIMMessageChat)messageChatType;

//TODO:对于 conversationId 的得来，也就是说用户该如何事先创建好 conversation，可以加点示例代码。

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
///---- Initialize a unique single chat type object of LCIMChatController ----------
///---------------------------------------------------------------------------------------------

/*!
 * @param PeerId id of the peer, a unique single conversation should be initialized with this property.
 * @attention `peerId` can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCIMChatController is initialized with this method, the property named `conversationId` will be set automatically.
 *            The `conversaionId` will be unique, meaning that if the conversation between the current user id and the `peerId` has already existed,
 *            LeanCloudIMKit will reuse the conversation instead of creating a new one.
 * @return Initialized unique single chat type object of LCIMChatController
 */
- (instancetype)initWithPeerId:(NSString *)peerId;

///----------------------------------------------------------------------------------------------
///---- Initialize a single or group chat type object of LCIMChatController ---------
///----------------------------------------------------------------------------------------------

/*!
 * @param conversationId Id of the conversation, group conversation should be initialized with this property.
 * @attention ConversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCIMChatController is initialized with this method, the property named `peerId` will be nil.
 * @return Initialized single or group chat type odject of LCIMChatController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

/*!
 *  是否禁止导航栏标题的自动设置，默认为NO;
 */
@property (nonatomic, assign) BOOL disableTitleAutoConfig;

/*!
 *  是否禁用文字的双击放大功能，默认为NO
 */
@property (nonatomic, assign) BOOL disableTextShowInFullScreen;

@end

@interface LCIMChatController (LCIMSendMessage)

#pragma mark - 消息发送

/*!
 * 文本发送
 */
- (void)sendTextMessage:(NSString *)text;

/* 图片发送 包含图片上传交互
 * @param image, 要发送的图片
 * @param useOriginImage, 是否强制发送原图
 */
- (void)sendImageMessage:(UIImage *)image useOriginImage:(BOOL)useOriginImage;
- (void)sendImageMessageData:(NSData *)ImageData useOriginImage:(BOOL)useOriginImage;

/*!
 * 语音发送
 */
- (void)sendVoiceMessage:(NSData*)wavData andTime:(NSTimeInterval)nRecordingTime;

@end

@interface LCIMChatController (LCIMBackgroundImage)

/*!
 * 通过接口设置背景图片
 */
@property (nonatomic, strong) UIImage *backgroundImage;

/*!
 *  在没有数据时显示该view，占据Controller的View整个页面
 */
@property (nonatomic, strong) UIView *placeHolder;

@end
