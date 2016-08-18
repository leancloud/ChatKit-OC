//
//  AVIMConversation+LCCKAddition.m
//  LeanCloudChatKit-iOS
//
//  v0.6.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "AVIMEmotionMessage.h"

static NSString *kAVIMEmotionPath = @"emotionPath";

@implementation AVIMEmotionMessage

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeEmotion;
}

+ (instancetype)messageWithEmotionPath:(NSString *)emotionPath {
    return [super messageWithText:nil file:nil attributes:@{kAVIMEmotionPath: emotionPath}];
}

- (NSString *)emotionPath {
    return [self.attributes objectForKey:kAVIMEmotionPath];
}

@end
