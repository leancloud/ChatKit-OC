//
//  LCCKVCardMessage.h
//  ChatKit-OC
//
//  Created by 陈宜龙 on 16/8/10.
//  v0.5.0 Copyright © 2016年 ElonChan. All rights reserved.
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

- (instancetype)initWithClientId:(NSString *)clientId;
+ (instancetype)vCardMessageWithClientId:(NSString *)clientId;

@end
