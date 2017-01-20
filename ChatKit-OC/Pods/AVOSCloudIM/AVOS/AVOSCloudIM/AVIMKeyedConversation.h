//
//  AVIMKeyedConversation.h
//  AVOS
//
//  Created by Tang Tianyong on 6/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVIMClient;
@class AVIMConversation;
@class AVIMMessage;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represents a conversation which intends to be archived. Can get this object from AVIMConversation by -[AVIMConversation keyedConversation]. Can convert this object to AVIMConverstaion by -[AVIMClient conversationWithKeyedConversation:].
 */
@interface AVIMKeyedConversation : NSObject <NSCoding>

@property (nonatomic, copy,   readonly, nullable) NSString     *conversationId; // 对话 id
@property (nonatomic, copy,   readonly, nullable) NSString     *creator;        // 创建者 id
@property (nonatomic, strong, readonly, nullable) NSDate       *createAt;       // 创建时间
@property (nonatomic, strong, readonly, nullable) NSDate       *updateAt;       // 最后更新时间
@property (nonatomic, strong, readonly, nullable) NSDate       *lastMessageAt;  // 对话中最后一条消息的发送时间
@property (nonatomic, strong, readonly, nullable) AVIMMessage  *lastMessage;  // 对话中最后一条消息的发送时间
@property (nonatomic, copy,   readonly, nullable) NSString     *name;           // 对话名字
@property (nonatomic, strong, readonly, nullable) NSArray      *members;        // 对话参与者列表
@property (nonatomic, strong, readonly, nullable) NSDictionary *attributes;     // 自定义属性
@property (nonatomic, assign, readonly)           BOOL          transient;      // 是否为临时会话（开放群组）
@property (nonatomic, assign, readonly)           BOOL          muted;          // 静音状态

@end

NS_ASSUME_NONNULL_END
