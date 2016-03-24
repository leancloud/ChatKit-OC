//
//  LCIMTableViewRowAction.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/24.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

@import Foundation;
@import UIKit;
@class LCIMTableViewRowAction;

typedef NS_ENUM(NSInteger, LCIMTableViewRowActionStyle) {
    LCIMTableViewRowActionStyleDefault = 0,
    LCIMTableViewRowActionStyleNormal
};

/**
 *  Item被点击后的回调，UserInfo中的Key预留，用于扩展，暂无定义
 */
typedef void (^LCIMTableViewRowActionHandler)(LCIMTableViewRowAction *action, NSIndexPath *indexPath);

@interface LCIMTableViewRowAction : UIButton

/**
 *  Item的显示名称
 */
@property (nonatomic, copy, nullable) NSString *title;

/**
 *  Item被点击后的回调
 */
@property (nonatomic, copy, readonly) LCIMTableViewRowActionHandler handler;
@property (nonatomic, readonly) LCIMTableViewRowActionStyle style;
@property (nonatomic, copy, nullable) UIVisualEffect* backgroundEffect;

/**
 *  是否合法：title和actionBlock非空
 */
- (BOOL)isValid;

/**
 *  背景色，默认红色
 */
@property (nonatomic, copy, nullable) UIColor *backgroundColor; // default background color is dependent on style

/**
 *  初始化
 */
+ (instancetype)rowActionWithStyle:(LCIMTableViewRowActionStyle)style title:(nullable NSString *)title handler:(LCIMTableViewRowActionHandler)handler;

@end

