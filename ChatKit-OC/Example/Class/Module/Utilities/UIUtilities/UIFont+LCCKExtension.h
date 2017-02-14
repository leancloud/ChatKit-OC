//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import <UIKit/UIKit.h>

@interface UIFont (LCCKExtension)

#pragma mark - Common
+ (UIFont *)lcck_fontNavBarTitle;

#pragma mark - Conversation
+ (UIFont *)lcck_fontConversationUsername;
+ (UIFont *)lcck_fontConversationDetail;
+ (UIFont *)lcck_fontConversationTime;

#pragma mark - Friends
+ (UIFont *)lcck_fontFriendsUsername;

#pragma mark - Mine
+ (UIFont *)lcck_fontMineNikename;
+ (UIFont *)lcck_fontMineUsername;

#pragma mark - Setting
+ (UIFont *)lcck_fontSettingHeaderAndFooterTitle;


#pragma mark - Chat
+ (UIFont *)lcck_fontTextMessageText;

@end
