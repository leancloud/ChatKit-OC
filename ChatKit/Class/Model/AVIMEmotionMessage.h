//
//  AVIMConversation+LCCKAddition.h
//  LeanCloudChatKit-iOS
//
//  v0.6.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/11.
//  Copyright © 2016年 ElonChan (微信向我报BUG:chenyilong1010). All rights reserved.
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

