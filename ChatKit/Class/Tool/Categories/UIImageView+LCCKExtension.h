//
//  UIImageView+LCCKExtension.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/5/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (LCCKExtension)

- (instancetype)initWithCornerRadiusAdvance:(CGFloat)cornerRadius rectCornerType:(UIRectCorner)rectCornerType;

- (void)lcck_cornerRadiusAdvance:(CGFloat)cornerRadius rectCornerType:(UIRectCorner)rectCornerType;

- (instancetype)initWithRoundingRectImageView;

- (void)lcck_cornerRadiusRoundingRect;

- (void)lcck_attachBorderWidth:(CGFloat)width color:(UIColor *)color;

@end
