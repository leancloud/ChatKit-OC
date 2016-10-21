//
//  MBProgressHUD+LCCKHUD.h
//  UberHackathon
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/1/16.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

@interface NSObject (LCCKHUD)

//---------------------显示成功,几秒后消失------------------------------------

/** 显示成功文字和图片,几秒后消失 */
+ (void)lcck_showSuccess:(NSString *)success;

/** 显示成功文字和图片,几秒后消失(放到指定view中) */
+ (void)lcck_showSuccess:(NSString *)success toView:(UIView *)view;

//------------------------显示出错,几秒后消失---------------------------------

/** 显示出错图片和文字,几秒后消失 */
+ (void)lcck_showError:(NSString *)error;

/** 显示出错图片和文字,几秒后消失(放到指定view中) */
+ (void)lcck_showError:(NSString *)error toView:(UIView *)view;

//--------------------------显示信息,几秒后消失-------------------------------

/**  只显示文字,几秒后消失 */
+ (void)lcck_showText:(NSString *)text;
/**  只显示文字,几秒后消失(放到指定view中) */
+ (void)lcck_showText:(NSString *)text toView:(UIView *)view;

/**  只显示图片,几秒后消失 */
+ (void)lcck_showIcon:(NSString *)icon;
/**  只显示图片,几秒后消失(放到指定view中) */
+ (void)lcck_showIcon:(NSString *)icon view:(UIView *)view;

/**  显示文字和图片,几秒后消失 */
+ (void)lcck_showText:(NSString *)text icon:(NSString *)icon;
/**  显示文字和图片,几秒后消失(放到指定view中) */
+ (void)lcck_showText:(NSString *)text icon:(NSString *)icon view:(UIView *)view;


//*******************************我是快乐的分割线*************************************
//--------------------------显示HUD-------------------------------
/** 只显示菊花(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)lcck_showHUD;
/** 显示菊花和文字(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)lcck_showMessage:(NSString *)message;
/** 显示菊花和文字(需要主动让它消失，HUD放到指定view中) */
+ (MBProgressHUD *)lcck_showMessage:(NSString *)message toView:(UIView *)view;

//--------------------------隐藏HUD-------------------------------
/** 隐藏HUD(HUD在Window中) */
+ (void)lcck_hideHUD;
/** 隐藏HUD(HUD在指定view中) */
+ (void)lcck_hideHUDForView:(UIView *)view;

- (void)lcck_showNetworkIndicator;

- (void)lcck_hideNetworkIndicator;

- (void)lcck_showProgress;

- (void)lcck_hideProgress;

- (void)lcck_alert:(NSString *)text;

- (BOOL)lcck_alertError:(NSError *)error;

- (BOOL)lcck_filterError:(NSError *)error;

- (void)lcck_showHUDText:(NSString *)text;

- (void)lcck_toast:(NSString *)text;

- (void)lcck_toast:(NSString *)text duration:(NSTimeInterval)duration;

- (void)lcck_showErrorAlert:(NSString *)text;

- (void)lcck_showSuccessAlert:(NSString *)text;

@end
