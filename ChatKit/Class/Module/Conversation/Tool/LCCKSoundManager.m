//
//  LCCKSoundManager.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//  声音设置、播放管理类。设置带有持久化功能。会把设置写入 NSUserDefaults，并在启动时加载

#import "LCCKSoundManager.h"
#import <AudioToolbox/AudioToolbox.h>

#define STR_BY_SEL(sel) NSStringFromSelector(@selector(sel))

@interface LCCKSoundManager ()

@property (nonatomic, assign) SystemSoundID loudReceiveSound;
@property (nonatomic, assign) SystemSoundID sendSound;
@property (nonatomic, assign) SystemSoundID receiveSound;

@end
@implementation LCCKSoundManager


+ (instancetype)defaultManager {
    static LCCKSoundManager *soundManager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        soundManager = [[LCCKSoundManager alloc] init];
    });
    return soundManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setDefaultSettings];
        self.needPlaySoundWhenChatting =  [[[NSUserDefaults standardUserDefaults] objectForKey:STR_BY_SEL(needPlaySoundWhenChatting)] boolValue];
        self.needPlaySoundWhenNotChatting  = [[[NSUserDefaults standardUserDefaults] objectForKey:STR_BY_SEL(needPlaySoundWhenNotChatting)] boolValue];
        self.needVibrateWhenNotChatting = [[[NSUserDefaults standardUserDefaults] objectForKey:STR_BY_SEL(needVibrateWhenNotChatting)] boolValue];
        [self createSoundWithName:[self soundNameWithBundlePath:@"loudReceive"] soundId:&_loudReceiveSound];
        [self createSoundWithName:[self soundNameWithBundlePath:@"send"] soundId:&_sendSound];
        [self createSoundWithName:[self soundNameWithBundlePath:@"receive"] soundId:&_receiveSound];
    }
    return self;
}

//FIXME:sound play failed
- (NSString *)soundNameWithBundlePath:(NSString *)soundName {
    NSString *soundNameWithBundlePath = [NSString stringWithFormat:@"VoiceMessageSource.bundle/%@", soundName];
    return soundNameWithBundlePath;
}

- (void)createSoundWithName:(NSString *)name soundId:(SystemSoundID *)soundId {
    NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:@"caf"];
    OSStatus errorCode = AudioServicesCreateSystemSoundID((__bridge CFURLRef)(url) , soundId);
    if (errorCode != 0) {
        NSLog(@"create sound failed");
    }
}

- (void)playSendSoundIfNeed {
    if (self.needPlaySoundWhenChatting) {
        AudioServicesPlaySystemSound(_sendSound);
    }
}

- (void)playReceiveSoundIfNeed {
    if (self.needPlaySoundWhenChatting) {
        AudioServicesPlaySystemSound(_receiveSound);
    }
}

- (void)playLoudReceiveSoundIfNeed {
    if (self.needPlaySoundWhenNotChatting) {
        AudioServicesPlaySystemSound(_loudReceiveSound);
    }
}

- (void)vibrateIfNeed {
    if (self.needVibrateWhenNotChatting) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

#pragma mark - local data

- (void)setNeedPlaySoundWhenChatting:(BOOL)needPlaySoundWhenChatting {
    _needPlaySoundWhenChatting = needPlaySoundWhenChatting;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.needPlaySoundWhenChatting) forKey:STR_BY_SEL(needPlaySoundWhenChatting)];
}

- (void)setNeedPlaySoundWhenNotChatting:(BOOL)needPlaySoundWhenNotChatting {
    _needPlaySoundWhenNotChatting = needPlaySoundWhenNotChatting;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.needPlaySoundWhenNotChatting) forKey:STR_BY_SEL(needPlaySoundWhenNotChatting)];
}

- (void)setNeedVibrateWhenNotChatting:(BOOL)needVibrateWhenNotChatting {
    _needVibrateWhenNotChatting = needVibrateWhenNotChatting;
    [[NSUserDefaults standardUserDefaults] setObject:@(self.needVibrateWhenNotChatting) forKey:STR_BY_SEL(needVibrateWhenNotChatting)];
}


- (void)setDefaultSettings {
    NSString *defaultSettingsFile = [[NSBundle mainBundle] pathForResource:@"defaultSettings" ofType:@"plist"];
    NSDictionary *defaultSettings = [[NSDictionary alloc] initWithContentsOfFile:defaultSettingsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettings];
}

@end
