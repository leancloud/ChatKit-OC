//
//  AVIMConversation+LCCKAddition.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//
#import <AVOSCloudIM/AVIMConversation.h>
#import "LCCKConversationService.h"
#import "LCCKConstants.h"
#import "LCCKChatUntiles.h"

@interface AVIMConversation (LCCKAddition)

/**
 *  最后一条消息。通过 SDK 的消息缓存找到的
 */
@property (nonatomic, strong) AVIMTypedMessage *lcck_lastMessage;

/**
 *  未读消息数，保存在了数据库。收消息的时候，更新数据库
 */
@property (nonatomic, assign) NSInteger lcck_unreadCount;

/**
 *  是否有人提到了你，配合 @ 功能。不能看最后一条消息。
 *  因为可能倒数第二条消息提到了你，所以维护一个标记。
 */
@property (nonatomic, assign) BOOL lcck_mentioned;

/**
 *  对话的类型，因为可能是两个人的群聊。所以不能通过成员数量来判断
 *
 *  @return 单聊或群聊
 */
- (LCCKConversationType)lcck_type;

/**
 *  单聊对话的对方的 clientId
 */
- (NSString *)lcck_peerId;

/**
 *  对话显示的名称。单聊显示对方名字，群聊显示对话的 name
 */
- (NSString *)lcck_displayName;

/**
 *  对话的标题。如 兴趣群(30)
 */
- (NSString *)lcck_title;

/**
 *  组合多个用户的名字。如 小王、老李
 *
 *  @param userIds 用户的 userId 集合
 *
 *  @return 拼成的名字
 */
+ (NSString *)lcck_groupConversaionDefaultNameForUserIds:(NSArray *)userIds;

@end
