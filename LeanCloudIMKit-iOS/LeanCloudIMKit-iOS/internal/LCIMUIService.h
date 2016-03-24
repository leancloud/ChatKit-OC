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

@interface LCIMUIService : NSObject <LCIMUIService>

+ (instancetype)sharedInstance;

/**
 *  未读数发生变化
 *  @param aCount 总的未读数
 */
typedef void(^LCIMUnreadCountChangedBlock)(NSInteger aCount);

/**
 *  新消息通知
 */
typedef void(^LCIMOnNewMessageBlock)(NSString *aSenderId, NSString *aContent, NSInteger aType, NSDate *aTime);


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

/**
 *  @brief 设置IMUIKit界面绘制所需资源包，默认使用自带资源包。
 *  @param customizedUIResources 自定义界面后所使用的资源包。
 *  @return 是否成功设置
 */
- (BOOL)setCustomizedUIResources:(NSBundle *)customizedUIResources;

@end
