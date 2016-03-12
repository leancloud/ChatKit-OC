//
//  LCIMUtil.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMUtil.h"
#import "MBProgressHUD.h"
#import "TWMessageBarManager.h"
#import "LCIMConstants.h"

@implementation LCIMUtil

+ (NSError *)errorWithText:(NSString *)text {
    NSInteger code = 0;
    NSString *errorReasonText = text;
    NSDictionary *errorInfo = @{
                                @"code":@(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:@"LeanCloudIMKitExample"
                                         code:code
                                     userInfo:errorInfo];
    
    
    return error;
}

+ (void)showProgressText:(NSString *)text duration:(NSTimeInterval)duration {
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    //    hud.labelText=text;
    hud.detailsLabelFont = [UIFont systemFontOfSize:14];
    hud.detailsLabelText = text;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud hide:YES afterDelay:duration];
}

+ (void)showProgress {
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    [MBProgressHUD showHUDAddedTo:window animated:YES];
}

+ (void)hideProgress {
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    [MBProgressHUD hideHUDForView:window animated:YES];
}

- (void)showNotificationWithTitle:(NSString *)title subtitle:(NSString *)subtitle type:(LCIMMessageNotificationType)type duration:(CGFloat)duration {
    /**
     在这里使用了LCIMKit提供的默认样式显示提示信息
     在你的app中，也可以换成你app中已有的提示方式
     */
    
    //TODO:
    TWMessageBarMessageType type_;
    switch (type) {
        case LCIMMessageNotificationTypeError:
            type_ = TWMessageBarMessageTypeError;
            break;
        case LCIMMessageNotificationTypeSuccess:
            type_ = TWMessageBarMessageTypeSuccess;
            break;
        case LCIMMessageNotificationTypeWarning:
            type_ = TWMessageBarMessageTypeInfo;
            break;
        case LCIMMessageNotificationTypeMessage:
            type_ = TWMessageBarMessageTypeInfo;
            break;
    }
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:localize(@"message.bar.info.title", title)
                                                   description:localize(@"message.bar.info.message", subtitle)
                                                          type:type_
                                                      duration:duration
                                                      callback:nil];
}

- (void)showNotificationWithTitle:(NSString *)title subtitle:(NSString *)subtitle type:(LCIMMessageNotificationType)type {
    [self showNotificationWithTitle:title subtitle:subtitle type:type duration:1.f];
}

- (void)hideNotification {
    [[TWMessageBarManager sharedInstance] hideAll];
}

@end
