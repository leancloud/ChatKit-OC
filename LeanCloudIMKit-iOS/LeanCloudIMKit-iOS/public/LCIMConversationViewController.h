//
//  LCIMConversationViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Base ViewController for chatting.

#import "LCIMUserModelDelegate.h"
#import "LCIMBaseViewController.h"
#import "LCIMServiceDefinition.h"

@class AVIMConversation;

/*
 
 LCIMConversationViewController gives a base ViewController for chatting.
 
 To use LCIMConversationViewController, follow these steps:
 
 1. Subclass LCIMConversationViewController
 2. Initialize the subclass by one of these methods: `-initWithConversationId:`, `-initWithPeerId:`.

 */

@interface LCIMConversationViewController : LCIMBaseViewController <LCIMConversationService>

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
///---- Initialize a unique single chat type object of LCIMConversationViewController ----------
///---------------------------------------------------------------------------------------------

/*!
 * @param PeerId id of the peer, a unique single conversation should be initialized with this property.
 * @attention `peerId` can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCIMConversationViewController is initialized with this method, the property named `conversationId` will be set automatically.
 *            The `conversaionId` will be unique, meaning that if the conversation between the current user id and the `peerId` has already existed, 
 *            LeanCloudIMKit will reuse the conversation instead of creating a new one.
 * @return Initialized unique single chat type object of LCIMConversationViewController
 */
- (instancetype)initWithPeerId:(NSString *)peerId;

///----------------------------------------------------------------------------------------------
///---- Initialize a single or group chat type object of LCIMConversationViewController ---------
///----------------------------------------------------------------------------------------------

/*!
 * @param conversationId Id of the conversation, group conversation should be initialized with this property.
 * @attention ConversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            If LCIMConversationViewController is initialized with this method, the property named `peerId` will be nil.
 * @return Initialized single or group chat type odject of LCIMConversationViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

@end

