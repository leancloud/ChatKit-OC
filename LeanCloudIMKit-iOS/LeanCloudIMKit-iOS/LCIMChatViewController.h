//
//  LCIMChatViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import Foundation;
@import UIKit;
#import "LCIMUserModelDelegate.h"

/*
 
 LCIMChatViewController give a base ViewController for chat.
 
 To use LCIMChatViewController, follow these steps:
 
 1. Subclass LCIMChatViewController
 2. Initialize the subclass by one of these methods: `-initWithConversationId:`, `-initWithMemberId:`, `+chatViewControllerWithConversationId:`, `+chatViewControllerWithMemberId:`.

 */


@interface LCIMChatViewController : UIViewController

/*!
 *  @brief id of the group conversation, group conversation should be initialized with this property.
 *  @details initialization methods are `-initWithConversationId:` and `+chatViewControllerWithConversationId:`.
 */
@property (nonatomic, copy, readonly) NSString *conversationId;

/*!
 *  @brief id of the peer, single conversation should be initialized with this property.
 *  @details initialization methods are `-initWithMemberId:` and `+chatViewControllerWithMemberId`.
 */
@property (nonatomic, copy, readonly) NSString *memberId;

///-----------------------------------------------------------------------
///---- initialize a single chat type object of LCIMChatViewController ---
///-----------------------------------------------------------------------

/*!
 * @param memberId id of the peer, single conversation should be initialized with this property.
 * @attention memberId can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            if LCIMChatViewController is initialized with this method, the property named `conversationId` will be set automatically.
 * @return initialized single chat type object of LCIMChatViewController
 */
- (instancetype)initWithMemberId:(NSString *)memberId;

/*!
 * @param memberId id of the peer, single conversation should be initialized with this property.
 * @attention memberId can not be equal to current user id, if yes, LeanCloudKit will throw an exception to notice you.
 *            if LCIMChatViewController is initialized with this method, the property named `conversationId` will be set automatically.
 * @return initialized single chat type odject of LCIMChatViewController
 */
+ (instancetype)chatViewControllerWithMemberId:(NSString *)memberId;

///---------------------------------------------------------------------------
///- initialize a single or group chat type object of LCIMChatViewController -
///---------------------------------------------------------------------------

/*!
 * @param conversationId id of the conversation, group conversation should be initialized with this property.
 * @attention conversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            if LCIMChatViewController is initialized with this method, the property named `memberId` will be nil.
 * @return initialized single or group chat type odject of LCIMChatViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

/*!
 * @param conversationId id of the conversation, group conversation should be initialized with this property.
 * @attention conversationId can not be nil, if yes, LeanCloudKit will throw an exception to notice you.
 *            if LCIMChatViewController is initialized with this method, the property named `memberId` will be nil.
 * @return initialized single or group chat type odject of LCIMChatViewController
 */
+ (instancetype)chatViewControllerWithConversationId:(NSString *)conversationId;

//- (void)didSelectAvatarOnMessage:(id<LCIMMessageModel>)message indexPath:(NSIndexPath *)indexPath;
//
//- (void)didSelectMember:(id<LCIMUserModelDelegate>)member;

@end
