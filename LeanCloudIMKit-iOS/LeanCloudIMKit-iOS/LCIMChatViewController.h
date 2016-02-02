//
//  LCIMChatViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface LCIMChatViewController : UIViewController

/*!
 *  @brief Id of the group conversation, group conversation shoud be initialized with this property.
 *  @details Initialization mehods are `-initWithConversationId:` and `+chatWithConversationId:`.
 */
@property (nonatomic, copy, readonly) NSString *conversationId;

/*!
 *  @brief Id of the peer, single conversation shoud be initialized with this property.
 *  @details Initialization mehods are `-initWithMemberId:` and `+chatWithMemberId`.
 */
@property (nonatomic, copy, readonly) NSString *memberId;

/*!
 *  @param conversationId Id of the group conversation, group conversation shoud be initialized with this property.
 *  @return Initialized object of LCIMChatViewController
 */
- (instancetype)initWithConversationId:(NSString *)conversationId;

/*!
 *  @param conversationId Id of the group conversation, group conversation shoud be initialized with this property.
 *  @return Initialized object of LCIMChatViewController
 */
+ (instancetype)chatWithConversationId:(NSString *)conversationId;

/*!
 * @param memberId Id of the peer, single conversation shoud be initialized with this property.
 * @return Initialized object of LCIMChatViewController
 */
- (instancetype)initWithMemberId:(NSString *)memberId;

/*!
 * @param memberId Id of the peer, single conversation shoud be initialized with this property.
 * @return Initialized object of LCIMChatViewController
 */
+ (instancetype)chatWithMemberId:(NSString *)memberId;

@end
