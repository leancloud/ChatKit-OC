//
//  LCIMChatViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Base ViewController for chatting.

#import "LCIMUserModelDelegate.h"

/*
 
 LCIMChatViewController gives a base ViewController for chatting.
 
 To use LCIMChatViewController, follow these steps:
 
 1. Subclass LCIMChatViewController
 2. Initialize the subclass by one of these methods: `-initWithConversationId:`, `-initWithMemberId:`.

 */

@interface LCIMChatViewController : UIViewController

/*!
 *  @brief Id of the single or group conversation, group conversation should be initialized with this property.
 *  @details Initialization method is `-initWithConversationId:`.
 */
@property (nonatomic, copy, readonly) NSString *conversationId;

/*!
 *  @brief Id of the peer, single conversation should be initialized with this property.
 *  @details Initialization method is `-initWithMemberId:`.
 */
@property (nonatomic, copy, readonly) NSString *memberId;

///--------------------------------------------------------------------------------
///---- Initialize a unique single chat type object of LCIMChatViewController -----
///--------------------------------------------------------------------------------

/*!
 * @param MemberId id of the peer, a unique single conversation should be initialized with this property.
 * @attention `memberId` can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCIMChatViewController is initialized with this method, the property named `conversationId` will be set automatically.
 *            The `conversaionId` will be unique, meaning that if the conversation between the current user id and the `memberId` has already existed, 
 *            LeanCloudIMKit will reuse the conversation instead of creating a new one.
 * @return Initialized unique single chat type object of LCIMChatViewController
 */
- (instancetype)initWithMemberId:(NSString *)memberId;

///---------------------------------------------------------------------------------
///---- Initialize a single or group chat type object of LCIMChatViewController ----
///---------------------------------------------------------------------------------

/*!
 * @param conversationId Id of the conversation, group conversation should be initialized with this property.
 * @attention ConversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCIMChatViewController is initialized with this method, the property named `memberId` will be nil.
 * @return Initialized single or group chat type odject of LCIMChatViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

@end
