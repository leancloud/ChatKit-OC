//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import <UIKit/UIKit.h>

@interface UIColor (TLChat)

#pragma mark - # 字体
+ (UIColor *)lcck_colorTextBlack;
+ (UIColor *)lcck_colorTextGray;
+ (UIColor *)lcck_colorTextGray1;


#pragma mark - 灰色
+ (UIColor *)lcck_colorGrayBG;           // 浅灰色默认背景
+ (UIColor *)lcck_colorGrayCharcoalBG;   // 较深灰色背景（聊天窗口, 朋友圈用）
+ (UIColor *)lcck_colorGrayLine;
+ (UIColor *)lcck_colorGrayForChatBar;
+ (UIColor *)lcck_colorGrayForMoment;


#pragma mark - 绿色
+ (UIColor *)lcck_colorGreenDefault;


#pragma mark - 蓝色
+ (UIColor *)lcck_colorBlueMoment;


#pragma mark - 黑色
+ (UIColor *)lcck_colorBlackForNavBar;
+ (UIColor *)lcck_colorBlackBG;
+ (UIColor *)lcck_colorBlackAlphaScannerBG;
+ (UIColor *)lcck_colorBlackForAddMenu;
+ (UIColor *)lcck_colorBlackForAddMenuHL;


@end
