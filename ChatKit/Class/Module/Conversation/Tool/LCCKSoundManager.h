//
//  LCCKSoundManager.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCCKSoundManager : NSObject

/**
 *  单例
 *  @return
 */
+ (instancetype)defaultManager;

/**
 *  消息到来了，但没有在聊天，是否需要振动
 */
@property (nonatomic, assign) BOOL needVibrateWhenNotChatting;

/**
 * 消息到来了，但没有在聊天，是否需要播放音效
 */
@property (nonatomic, assign) BOOL needPlaySoundWhenNotChatting;

/**
 *  聊着天时，发送和接收消息，是否需要音效
 */
@property (nonatomic, assign) BOOL needPlaySoundWhenChatting;

/**
 *  根据需要播放发送消息音效
 */
- (void)playSendSoundIfNeed;

/**
 *  根据需要播放接收消息音效
 */
- (void)playReceiveSoundIfNeed;

/**
 *  根据需要播放较响亮的接收消息音效
 */
- (void)playLoudReceiveSoundIfNeed;

/**
 *  根据需要来振动
 */
- (void)vibrateIfNeed;

@end
