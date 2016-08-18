//
//  LCCKUtil.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import Foundation;
@import UIKit;
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
@interface LCCKUtil : NSObject

+ (NSError *)errorWithText:(NSString *)text;
+ (void)showProgressText:(NSString *)text duration:(NSTimeInterval)duration;
+ (void)showProgress;
+ (void)hideProgress;

/**
 *  显示提示信息
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(LCCKMessageNotificationType)type;

/**
 *  显示提示信息
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(LCCKMessageNotificationType)type
                         duration:(CGFloat)duration;

/**
 *  显示提示信息
 */
+ (void)hideNotification;

@end
