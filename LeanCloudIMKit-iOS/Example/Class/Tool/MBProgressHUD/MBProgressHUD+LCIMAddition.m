//
//  MBProgressHUD+LCIMAddition.m
//  UberHackathon
//
//  Created by 陈宜龙 on 16/1/16.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import "MBProgressHUD+LCIMAddition.h"

// 正常是2秒
static CGFloat const kTime = 2.0f;

@implementation UIViewController (LCIMAddition)


//---------------------显示成功,几秒后消失------------------------------------
/** 显示成功文字和图片,几秒后消失 */
+ (void)showSuccess:(NSString *)success {
    [self showText:success icon:@"success.png" view:nil];
}
/** 显示成功文字和图片,几秒后消失(放到指定view中) */
+ (void)showSuccess:(NSString *)success toView:(UIView *)view {
    [self showText:success icon:@"success.png" view:view];
}

//------------------------显示出错,几秒后消失---------------------------------
/** 显示出错图片和文字,几秒后消失 */
+ (void)showError:(NSString *)error {
    [self showText:error icon:@"error.png" view:nil];
}
/** 显示出错图片和文字,几秒后消失(放到指定view中) */
+ (void)showError:(NSString *)error toView:(UIView *)view {
    [self showText:error icon:@"error.png" view:view];
}

//--------------------------显示信息,几秒后消失-------------------------------
/**  只显示文字,几秒后消失 */
+ (void)showText:(NSString *)text {
    [self showText:text icon:nil view:nil];
}
/**  只显示文字,几秒后消失(放到指定view中) */
+ (void)showText:(NSString *)text view:(UIView *)view {
    [self showText:text icon:nil view:view];
}

/**  只显示图片,几秒后消失 */
+ (void)showIcon:(NSString *)icon {
    [self showText:nil icon:icon view:nil];
}
/**  只显示图片,几秒后消失(放到指定view中) */
+ (void)showIcon:(NSString *)icon view:(UIView *)view {
    [self showText:nil icon:icon view:view];
}

/**  显示文字和图片,几秒后消失 */
+ (void)showText:(NSString *)text icon:(NSString *)icon {
    [self showText:text icon:icon view:nil];
}
/**  显示文字和图片,几秒后消失(放到指定view中) */
+ (void)showText:(NSString *)text icon:(NSString *)icon view:(UIView *)view {
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    hud.labelText = text;
    hud.labelFont = [UIFont systemFontOfSize:22];
    hud.minSize = CGSizeMake(160, 160);
    //GCC的C扩充功能Code Block Evaluation，
    //    hud.color = kColorTheme;
    
    // YES代表需要蒙版效果(默认是NO)
    //    hud.dimBackground = YES;
    
    // 设置图片
    NSString *imgStr = [NSString stringWithFormat:@"MBProgressHUD.bundle/%@", icon];
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imgStr]];
    
    // 再设置模式
    hud.mode = MBProgressHUDModeCustomView;
    
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    
    // 几秒之后再消失
    [hud hide:YES afterDelay:kTime];
}


//*******************************我是快乐的分割线*************************************/
//--------------------------显示HUD-------------------------------
/** 只显示菊花(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)showHUD {
    return [self showMessage:nil toView:nil];
}

/** 显示菊花和文字(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)showMessage:(NSString *)message {
    return [self showMessage:message toView:nil];
}

/** 显示菊花和文字(需要主动让它消失，HUD放到指定view中) */
+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view {
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = message;
    
    hud.labelFont = [UIFont systemFontOfSize:22];
    hud.minSize = CGSizeMake(160, 160);
    //    hud.size = CGSizeMake(100, 100);
    
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果(默认是NO)
    //    hud.dimBackground = YES;
    
    return hud;
}

//--------------------------隐藏HUD-------------------------------
/** 隐藏HUD(HUD在Window中) */
+ (void)hideHUD {
    [self hideHUDForView:nil];
}

/** 隐藏HUD(HUD在指定view中) */
+ (void)hideHUDForView:(UIView *)view {
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    [[self class] hideHUDForView:view animated:YES];
}


- (void)alert:(NSString*)text {
    [[self class] showText:text];
}

- (BOOL)alertError:(NSError *)error {
    if (error) {
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), error.description);
//        [AVAnalytics event:@"Alert Error" attributes:@{@"desc": error.description}];
    }
    if (error) {
//        if (error.code == kAVIMErrorConnectionLost) {
//            [self alert:@"未能连接聊天服务"];
//        }
//        else
            if ([error.domain isEqualToString:NSURLErrorDomain]) {
            [self alert:@"网络连接发生错误"];
        }
        else {
#ifndef DEBUG
            [self alert:[NSString stringWithFormat:@"%@", error]];
#else
            NSString *info = error.localizedDescription;
            [self alert:info ? info : [NSString stringWithFormat:@"%@", error]];
#endif
        }
        return YES;
    }
    return NO;
}

- (BOOL)filterError:(NSError *)error {
    return [self alertError:error] == NO;
}

- (void)showErrorAlert:(NSString *)text {
    [[self class] showError:text];
}

- (void)showSuccessAlert:(NSString *)text {
    [[self class] showSuccess:text];
}

- (void)toast:(NSString *)text duration:(NSTimeInterval)duration {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    //    hud.labelText=text;
    hud.detailsLabelFont = [UIFont systemFontOfSize:14];
    hud.detailsLabelText = text;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:duration];
}

-(void)showNetworkIndicator{
    UIApplication *app=[UIApplication sharedApplication];
    app.networkActivityIndicatorVisible=YES;
}

- (void)hideNetworkIndicator{
    UIApplication *app=[UIApplication sharedApplication];
    app.networkActivityIndicatorVisible=NO;
}

- (void)showProgress {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

-(void)hideProgress {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

-(void)showHUDText:(NSString*)text{
    [self toast:text];
}

- (void)toast:(NSString *)text {
    [self toast:text duration:2];
}

@end
