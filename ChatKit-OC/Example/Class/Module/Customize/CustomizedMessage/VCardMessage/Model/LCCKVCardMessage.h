//
//  LCCKVCardMessage.h
//  ChatKit-OC
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/8/10.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <AVOSCloudIM/AVOSCloudIM.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

static AVIMMessageMediaType const kAVIMMessageMediaTypeVCard = 1;

#import "LCCKVCardMessage.h"

@interface LCCKVCardMessage : AVIMTypedMessage<AVIMTypedMessageSubclassing>

- (instancetype)initWithClientId:(NSString *)clientId conversationType:(LCCKConversationType)conversationType;
+ (instancetype)vCardMessageWithClientId:(NSString *)clientId conversationType:(LCCKConversationType)conversationType;

@end
