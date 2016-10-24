//
//  MBProgressHUD+LCCKHUD.m
//  UberHackathon
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/1/16.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import "NSObject+LCCKHUD.h"

static CGFloat const kTime = 20;
static CGFloat const kSuccessMessageTime = 0.3f;
static CGFloat const kFailureMessageTime = 0.3f;

@implementation NSObject (LCCKHUD)


//---------------------显示成功,几秒后消失------------------------------------
/** 显示成功文字和图片,几秒后消失 */
+ (void)lcck_showSuccess:(NSString *)success {
    [self lcck_showText:success icon:@"success.png" view:nil afterDelay:kSuccessMessageTime];
}
/** 显示成功文字和图片,几秒后消失(放到指定view中) */
+ (void)lcck_showSuccess:(NSString *)success toView:(UIView *)view {
    [self lcck_showText:success icon:@"success.png" view:view afterDelay:kSuccessMessageTime];
}

//------------------------显示出错,几秒后消失---------------------------------
/** 显示出错图片和文字,几秒后消失 */
+ (void)lcck_showError:(NSString *)error {
    [self lcck_showText:error icon:@"error.png" view:nil afterDelay:kFailureMessageTime];
}
/** 显示出错图片和文字,几秒后消失(放到指定view中) */
+ (void)lcck_showError:(NSString *)error toView:(UIView *)view {
    [self lcck_showText:error icon:@"error.png" view:view afterDelay:kFailureMessageTime];
}

//--------------------------显示信息,几秒后消失-------------------------------
/**  只显示文字,几秒后消失 */
+ (void)lcck_showText:(NSString *)text {
    [self lcck_showText:text icon:nil view:nil];
}
/**  只显示文字,几秒后消失(放到指定view中) */
+ (void)lcck_showText:(NSString *)text toView:(UIView *)view {
    [self lcck_showText:text icon:nil view:view];
}

/**  只显示图片,几秒后消失 */
+ (void)lcck_showIcon:(NSString *)icon {
    [self lcck_showText:nil icon:icon view:nil];
}

/**  只显示图片,几秒后消失(放到指定view中) */
+ (void)lcck_showIcon:(NSString *)icon view:(UIView *)view {
    [self lcck_showText:nil icon:icon view:view];
}

/**  显示文字和图片,几秒后消失 */
+ (void)lcck_showText:(NSString *)text icon:(NSString *)icon {
    [self lcck_showText:text icon:icon view:nil];
}

+ (UIView *)rootWindowView {
    UIView *view = [[UIApplication sharedApplication].windows lastObject];
    return view;
}

+ (void)lcck_showText:(NSString *)text icon:(NSString *)icon view:(UIView *)view {
    [self lcck_showText:text icon:icon view:view afterDelay:kTime];
}

/**  显示文字和图片,几秒后消失(放到指定view中) */
+ (void)lcck_showText:(NSString *)text icon:(NSString *)icon view:(UIView *)view afterDelay:(NSTimeInterval)delay {
    if (view == nil) {
        view = [self rootWindowView];
    }
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    
    hud.labelText = text;
    hud.labelFont = [UIFont systemFontOfSize:22];
//    hud.minSize = CGSizeMake(100, 100);
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
    [hud hide:YES afterDelay:delay];
}


//*******************************我是快乐的分割线*************************************/
//--------------------------显示HUD-------------------------------
/** 只显示菊花(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)lcck_showHUD {
    return [self lcck_showMessage:nil toView:nil];
}

/** 显示菊花和文字(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)lcck_showMessage:(NSString *)message {
    return [self lcck_showMessage:message toView:nil];
}

/** 显示菊花和文字(需要主动让它消失，HUD放到指定view中) */
+ (MBProgressHUD *)lcck_showMessage:(NSString *)message toView:(UIView *)view {
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = message;
    
    hud.labelFont = [UIFont systemFontOfSize:22];
//    hud.minSize = CGSizeMake(100, 100);
    //    hud.size = CGSizeMake(100, 100);
    
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果(默认是NO)
    //    hud.dimBackground = YES;
    
    return hud;
}

//--------------------------隐藏HUD-------------------------------
/** 隐藏HUD(HUD在Window中) */
+ (void)lcck_hideHUD {
    [self lcck_hideHUDForView:nil];
}

/** 隐藏HUD(HUD在指定view中) */
+ (void)lcck_hideHUDForView:(UIView *)view {
    if (view == nil) {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    [MBProgressHUD hideHUDForView:view animated:YES];
}


- (void)lcck_alert:(NSString*)text {
    [[self class] lcck_showText:text];
}

- (BOOL)lcck_alertError:(NSError *)error {
    if (error) {
            if ([error.domain isEqualToString:NSURLErrorDomain]) {
            [self lcck_alert:@"网络连接发生错误"];
        } else {
#ifndef DEBUG
            [self lcck_alert:[NSString stringWithFormat:@"%@", error]];
#else
            NSString *info = error.localizedDescription;
            [self lcck_alert:info ? info : [NSString stringWithFormat:@"%@", error]];
#endif
        }
        return YES;
    }
    return NO;
}

- (BOOL)lcck_filterError:(NSError *)error {
    return [self lcck_alertError:error] == NO;
}

- (void)lcck_showErrorAlert:(NSString *)text {
    [[self class] lcck_showError:text];
}

- (void)lcck_showSuccessAlert:(NSString *)text {
    [[self class] lcck_showSuccess:text];
}

- (void)lcck_toast:(NSString *)text duration:(NSTimeInterval)duration {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[self class] rootWindowView] animated:YES];
    //    hud.labelText=text;
    hud.detailsLabelFont = [UIFont systemFontOfSize:14];
    hud.detailsLabelText = text;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:duration];
}

-(void)lcck_showNetworkIndicator{
    UIApplication *app=[UIApplication sharedApplication];
    app.networkActivityIndicatorVisible=YES;
}

- (void)lcck_hideNetworkIndicator{
    UIApplication *app=[UIApplication sharedApplication];
    app.networkActivityIndicatorVisible=NO;
}

- (void)lcck_showProgress {
    [MBProgressHUD showHUDAddedTo:[[self class] rootWindowView] animated:YES];
}

-(void)lcck_hideProgress {
    [MBProgressHUD hideHUDForView:[[self class] rootWindowView] animated:YES];
}

-(void)lcck_showHUDText:(NSString*)text{
    [self lcck_toast:text];
}

- (void)lcck_toast:(NSString *)text {
    [self lcck_toast:text duration:2];
}

@end
