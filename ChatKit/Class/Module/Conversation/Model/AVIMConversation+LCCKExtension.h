//
//  AVIMConversation+LCCKExtension.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/11.
//  Copyright © 2016年 ElonChan . All rights reserved.
//
#import <AVOSCloudIM/AVIMConversation.h>
#import "LCCKConversationService.h"
#import "LCCKConstants.h"
#import "LCCKConstants.h"

@interface AVIMConversation (LCCKExtension)

/**
 *  最后一条消息。通过 SDK 的消息缓存找到的
 */
@property (nonatomic, strong, readonly) AVIMTypedMessage *lcck_lastMessage;
@property (nonatomic, strong, readonly) NSDate *lcck_lastMessageAt;

/**
 *  未读消息数，保存在了数据库。收消息的时候，更新数据库
 */
@property (nonatomic, assign, readonly) NSInteger lcck_unreadCount;

/*!
 * 如果未读消息数未超出100，显示数字，否则显示省略号
 */
- (NSString *)lcck_badgeText;

/**
 *  是否有人提到了你，配合 @ 功能。不能看最后一条消息。
 *  因为可能倒数第二条消息提到了你，所以维护一个标记。
 */
@property (nonatomic, assign, readonly) BOOL lcck_mentioned;

/*!
 * 草稿
 */
@property (nonatomic, copy) NSString *lcck_draft;

/**
 *  对话的类型，通过成员数量来判断。系统对话按照群聊来处理。
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

- (void)lcck_setConversationWithMute:(BOOL)mute callback:(LCCKBooleanResultBlock)callback;
- (BOOL)lcck_isCreaterForCurrentUser;

@end
