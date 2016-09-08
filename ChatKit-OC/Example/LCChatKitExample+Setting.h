//
//  LCChatKitExample+Setting.h
//  ChatDemo
//
//  Created by zzgo on 16/9/7.
//  Copyright © 2016年 zzgo. All rights reserved.
//
#import "LCChatKitExample.h"
#import "MWPhotoBrowser.h"
#import <Foundation/Foundation.h>

@interface LCChatKitExample (Setting) //<MWPhotoBrowserDelegate>

/**
 *  初始化需要的设置
 */
- (void)lcck_setting;
+ (void)lcck_pushToViewController:(UIViewController *)viewController;
+ (void)lcck_tryPresentViewControllerViewController:(UIViewController *)viewController;
+ (void)lcck_clearLocalClientInfo;
+ (void)lcck_exampleChangeGroupAvatarURLsForConversationId:(NSString *)conversationId
                                         shouldInsert:(BOOL)shouldInsert;
@end