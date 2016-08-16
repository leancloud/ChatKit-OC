//
//  AVIMConversation+LCCKAddition.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//
#if __has_include(<AVOSCloudIM/AVIMTypedMessage.h>)
#import <AVOSCloudIM/AVIMTypedMessage.h>
#else
#import "AVIMTypedMessage.h"
#endif

static AVIMMessageMediaType const kAVIMMessageMediaTypeEmotion = 1;

@interface AVIMEmotionMessage : AVIMTypedMessage<AVIMTypedMessageSubclassing>

+ (instancetype)messageWithEmotionPath:(NSString *)emotionPath;

- (NSString *)emotionPath;

@end

