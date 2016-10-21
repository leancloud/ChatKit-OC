//
//  LCCKLastMessageTypeManager.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AVIMConversation;
@class AVIMTypedMessage;

@interface LCCKLastMessageTypeManager : NSObject

/**
 *  最近对话里的消息概要。 [有人@ 你] [20 条] 老王：今晚一起吃饭吗？
 *  @param message
 *  @param conversation 对话
 *  @return 修饰文本。红色的 [有人@你]
 */
+ (NSAttributedString *)attributedStringWithMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation userName:(NSString *)userName;

@end
