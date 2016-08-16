//
//  LCCKSoundManager.m
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//  声音设置、播放管理类。设置带有持久化功能。会把设置写入 NSUserDefaults，并在启动时加载

#import "LCCKSoundManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "NSBundle+LCCKExtension.h"

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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDefaultSettings];
        [self createSoundWithURL:[self soundURLWithName:@"loudReceive"] soundId:&_loudReceiveSound];
        [self createSoundWithURL:[self soundURLWithName:@"send"] soundId:&_sendSound];
        [self createSoundWithURL:[self soundURLWithName:@"receive"] soundId:&_receiveSound];
    }
    return self;
}

- (NSURL *)soundURLWithName:(NSString *)soundName {
    NSString *bundlePath = [NSBundle lcck_bundlePathForBundleName:@"VoiceMessageSource" class:[self class]];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSURL *url = [bundle URLForResource:soundName withExtension:@"caf"];
    return url;
}

- (void)createSoundWithURL:(NSURL *)URL soundId:(SystemSoundID *)soundId {
    OSStatus errorCode = AudioServicesCreateSystemSoundID((__bridge CFURLRef)(URL) , soundId);
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
    NSBundle *bundle = [NSBundle lcck_bundleForbundleName:@"Common" class:[self class]];
    NSString *defaultSettingsFile = [bundle pathForResource:@"LCChatKit-Settings" ofType:@"plist"];
    NSDictionary *defaultSettings = [[NSDictionary alloc] initWithContentsOfFile:defaultSettingsFile];
    NSDictionary *conversationSettings = defaultSettings[@"Conversation"];
    self.needPlaySoundWhenChatting =  [conversationSettings[STR_BY_SEL(needPlaySoundWhenChatting)] boolValue];
    self.needPlaySoundWhenNotChatting  = [conversationSettings[STR_BY_SEL(needPlaySoundWhenNotChatting)] boolValue];
    self.needVibrateWhenNotChatting = [conversationSettings[STR_BY_SEL(needVibrateWhenNotChatting)] boolValue];
}

@end
