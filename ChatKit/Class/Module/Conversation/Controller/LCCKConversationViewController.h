//
//  LCCKConversationViewController.h
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>
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
 *            conversationId 与 peerId 并不等同。您一般不能自己构造一个conversationId，而是从 conversation 等特定接口中才能读取到conversationId。如果需要使用personId来打开会话，应该使用 `-initWithPeerId:` 这个接口。
 * @return Initialized single or group chat type odject of LCCKConversationViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

/*!
 *  是否禁用文字的双击放大功能，默认为NO
 */
@property (nonatomic, assign) BOOL disableTextShowInFullScreen;

- (void)setConversationHandler:(LCCKConversationHandler)conversationHandler;
- (void)setLoadHistoryMessagesHandler:(LCCKBooleanResultBlock)loadHistoryMessagesHandler;

@end


