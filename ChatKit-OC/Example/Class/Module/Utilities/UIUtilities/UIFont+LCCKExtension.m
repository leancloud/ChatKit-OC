//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "UIFont+LCCKExtension.h"

@implementation UIFont (LCCKExtension)

+ (UIFont *)lcck_fontNavBarTitle {
    return [UIFont boldSystemFontOfSize:17.5f];
}

+ (UIFont *)lcck_fontConversationUsername {
    return [UIFont systemFontOfSize:17.0f];
}

+ (UIFont *)lcck_fontConversationDetail {
    return [UIFont systemFontOfSize:14.0f];
}

+ (UIFont *)lcck_fontConversationTime {
    return [UIFont systemFontOfSize:12.5f];
}

+ (UIFont *)lcck_fontFriendsUsername {
    return [UIFont systemFontOfSize:17.0f];
}

+ (UIFont *)lcck_fontMineNikename {
    return [UIFont systemFontOfSize:17.0f];
}

+ (UIFont *)lcck_fontMineUsername {
    return [UIFont systemFontOfSize:14.0f];
}

+ (UIFont *)lcck_fontSettingHeaderAndFooterTitle {
    return [UIFont systemFontOfSize:14.0f];
}

+ (UIFont *)lcck_fontTextMessageText {
    CGFloat size = [[NSUserDefaults standardUserDefaults] doubleForKey:@"CHAT_FONT_SIZE"];
    if (size == 0) {
        size = 16.0f;
    }
    return [UIFont systemFontOfSize:size];
}

@end
