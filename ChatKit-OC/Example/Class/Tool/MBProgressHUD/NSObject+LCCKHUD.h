//
//  MBProgressHUD+LCCKHUD.h
//  UberHackathon
//
//  Created by 陈宜龙 on 16/1/16.
//  Copyright © 2016年 微博@iOS程序犭袁. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

@interface NSObject (LCCKHUD)

//---------------------显示成功,几秒后消失------------------------------------

/** 显示成功文字和图片,几秒后消失 */
+ (void)showSuccess:(NSString *)success;

/** 显示成功文字和图片,几秒后消失(放到指定view中) */
+ (void)showSuccess:(NSString *)success toView:(UIView *)view;

//------------------------显示出错,几秒后消失---------------------------------

/** 显示出错图片和文字,几秒后消失 */
+ (void)showError:(NSString *)error;

/** 显示出错图片和文字,几秒后消失(放到指定view中) */
+ (void)showError:(NSString *)error toView:(UIView *)view;

//--------------------------显示信息,几秒后消失-------------------------------

/**  只显示文字,几秒后消失 */
+ (void)showText:(NSString *)text;
/**  只显示文字,几秒后消失(放到指定view中) */
+ (void)showText:(NSString *)text view:(UIView *)view;

/**  只显示图片,几秒后消失 */
+ (void)showIcon:(NSString *)icon;
/**  只显示图片,几秒后消失(放到指定view中) */
+ (void)showIcon:(NSString *)icon view:(UIView *)view;

/**  显示文字和图片,几秒后消失 */
+ (void)showText:(NSString *)text icon:(NSString *)icon;
/**  显示文字和图片,几秒后消失(放到指定view中) */
+ (void)showText:(NSString *)text icon:(NSString *)icon view:(UIView *)view;


//*******************************我是快乐的分割线*************************************
//--------------------------显示HUD-------------------------------
/** 只显示菊花(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)showHUD;
/** 显示菊花和文字(需要主动让它消失,HUD放在Window中) */
+ (MBProgressHUD *)showMessage:(NSString *)message;
/** 显示菊花和文字(需要主动让它消失，HUD放到指定view中) */
+ (MBProgressHUD *)showMessage:(NSString *)message toView:(UIView *)view;

//--------------------------隐藏HUD-------------------------------
/** 隐藏HUD(HUD在Window中) */
+ (void)hideHUD;
/** 隐藏HUD(HUD在指定view中) */
+ (void)hideHUDForView:(UIView *)view;

- (void)showNetworkIndicator;

- (void)hideNetworkIndicator;

- (void)showProgress;

- (void)hideProgress;

- (void)alert:(NSString *)text;

- (BOOL)alertError:(NSError *)error;

- (BOOL)filterError:(NSError *)error;

- (void)showHUDText:(NSString *)text;

- (void)toast:(NSString *)text;

- (void)toast:(NSString *)text duration:(NSTimeInterval)duration;

- (void)showErrorAlert:(NSString *)text;

- (void)showSuccessAlert:(NSString *)text;

@end
