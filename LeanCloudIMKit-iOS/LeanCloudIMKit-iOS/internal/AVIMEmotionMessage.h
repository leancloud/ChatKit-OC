//
//  AVIMConversation+LCIMAddition.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "AVIMTypedMessage.h"

static AVIMMessageMediaType const kAVIMMessageMediaTypeEmotion = 1;

@interface AVIMEmotionMessage : AVIMTypedMessage<AVIMTypedMessageSubclassing>

+ (instancetype)messageWithEmotionPath:(NSString *)emotionPath;

- (NSString *)emotionPath;

@end

