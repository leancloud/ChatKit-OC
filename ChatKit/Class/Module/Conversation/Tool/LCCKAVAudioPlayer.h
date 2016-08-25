//
//  LCCKAVAudioPlayer.h
//  LCCKChatExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/18.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

//  LCCKAVAudioPlayer
//  提供一个可以播放本地,网路MP3等格式的播放控制
//  网络音频统一缓存在documents/com.LeanCloud.LCCKChat.LCCKAudioCache目录下
//  播放流程
//  传入URLString,index->检测是否有正在加载,正在播放的音频(停止加载,停止播放)->检查URLString是本地还是网络路径(网络路径下载到本地,并且缓存到本地目录下)->开始播放加载到的audioData->播放结束

#import <Foundation/Foundation.h>

#import "LCCKConstants.h"

@protocol LCCKAVAudioPlayerDelegate <NSObject>

- (void)audioPlayerStateDidChanged:(LCCKVoiceMessageState)audioPlayerState identifier:(NSString *)identifier;

@end

@interface LCCKAVAudioPlayer : NSObject

@property (nonatomic, weak) id<LCCKAVAudioPlayerDelegate> delegate;

@property (nonatomic, copy) NSString *URLString;

/**
 *  identifier -> 主要作用是提供记录,用来控制对应的tableViewCell的状态
 */
@property (nonatomic, copy) NSString *identifier;

/**
 *  当前播放器播放的状态,当tableView滚动时,匹配index来设置对应的audioPlayerState
 */
@property (nonatomic, assign) LCCKVoiceMessageState audioPlayerState;

+ (instancetype)sharePlayer;

- (void)playAudioWithURLString:(NSString *)URLString identifier:(NSString *)identifier;

- (void)stopAudioPlayer;

- (void)cleanAudioCache;

@end
