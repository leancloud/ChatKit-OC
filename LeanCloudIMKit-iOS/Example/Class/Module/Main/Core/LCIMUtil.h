//
//  LCIMUtil.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import Foundation;
@import UIKit;
#import "LCIMKit.h"
@interface LCIMUtil : NSObject

+ (NSError *)errorWithText:(NSString *)text;
+ (void)showProgressText:(NSString *)text duration:(NSTimeInterval)duration;
+ (void)showProgress;
+ (void)hideProgress;

/**
 *  显示提示信息
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(LCIMMessageNotificationType)type;

/**
 *  显示提示信息
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(LCIMMessageNotificationType)type
                         duration:(CGFloat)duration;

/**
 *  显示提示信息
 */
+ (void)hideNotification;

@end
