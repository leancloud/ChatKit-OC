//
//  LCIMUIService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

/**
 *  UIService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCIMUIServiceErrorDomain;

/**
 *  提示信息的类型定义
 */
typedef NS_ENUM(NSInteger, LCIMMessageNotificationType) {
    /// 普通消息
    LCIMMessageNotificationTypeMessage = 0,
    /// 警告
    LCIMMessageNotificationTypeWarning,
    /// 错误
    LCIMMessageNotificationTypeError,
    /// 成功
    LCIMMessageNotificationTypeSuccess
};
@interface LCIMUIService : NSObject <LCIMUIService>

+ (instancetype)sharedInstance;

/**
 *  当IMUIKit需要显示通知时，会调用这个block。
 *  开发者需要实现并设置这个block，以便给用户提示。
 *  @param viewController 当前的controller
 *  @param title 标题
 *  @param subtitle 子标题
 *  @param type 类型
 */
typedef void(^LCIMShowNotificationBlock)(UIViewController *viewController, NSString *title, NSString *subtitle, LCIMMessageNotificationType type);

/**
 *  未读数发生变化
 *  @param aCount 总的未读数
 */
typedef void(^LCIMUnreadCountChangedBlock)(NSInteger aCount);

/**
 *  新消息通知
 */
typedef void(^LCIMOnNewMessageBlock)(NSString *aSenderId, NSString *aContent, NSInteger aType, NSDate *aTime);

@property (nonatomic, copy, readonly) LCIMOpenProfileBlock openProfileBlock;

/*!
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock;

/**
 *  导航栏返回按钮，如果没有设置，则为默认返回字样
 */
@property (nonatomic, strong) UIButton *navigationBackButton;

/**
 *  设置会话列表和聊天界面头像ImageView的contentMode
 */
- (void)setAvatarImageViewContentMode:(UIViewContentMode)mode;

/**
 *  设置会话列表和聊天界面头像ImageView的圆角弧度
 *  注意，请在需要圆角矩形时设置，会话列表和聊天界面头像默认圆形。
 */
- (void)setAvatarImageViewCornerRadius:(CGFloat)cornerRadius;

@end
