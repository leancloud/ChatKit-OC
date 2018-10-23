//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#define LCCKColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:a]

#import "UIColor+LCCKExtension.h"

@implementation UIColor (TLChat)

#pragma mark - # 字体
+ (UIColor *)lcck_colorTextBlack {
    return [UIColor blackColor];
}

+ (UIColor *)lcck_colorTextGray {
    return [UIColor grayColor];
}

+ (UIColor *)lcck_colorTextGray1 {
    return LCCKColor(160, 160, 160, 1.0);
}

#pragma mark - 灰色
+ (UIColor *)lcck_colorGrayBG {
    return LCCKColor(239.0, 239.0, 244.0, 1.0);
}

+ (UIColor *)lcck_colorGrayCharcoalBG {
    return LCCKColor(235.0, 235.0, 235.0, 1.0);
}

+ (UIColor *)lcck_colorGrayLine {
    return [UIColor colorWithWhite:0.5 alpha:0.3];
}

+ (UIColor *)lcck_colorGrayForChatBar {
    return LCCKColor(245.0, 245.0, 247.0, 1.0);
}

+ (UIColor *)lcck_colorGrayForMoment {
    return LCCKColor(243.0, 243.0, 245.0, 1.0);
}

#pragma mark - 绿色
+ (UIColor *)lcck_colorGreenDefault {
    return LCCKColor(2.0, 187.0, 0.0, 1.0f);
}


#pragma mark - 蓝色
+ (UIColor *)lcck_colorBlueMoment {
    return LCCKColor(74.0, 99.0, 141.0, 1.0);
}

#pragma mark - 黑色
+ (UIColor *)lcck_colorBlackForNavBar {
    return LCCKColor(20.0, 20.0, 20.0, 1.0);
}

+ (UIColor *)lcck_colorBlackBG {
    return LCCKColor(46.0, 49.0, 50.0, 1.0);
}

+ (UIColor *)lcck_colorBlackAlphaScannerBG {
    return [UIColor colorWithWhite:0 alpha:0.6];
}

+ (UIColor *)lcck_colorBlackForAddMenu {
    return LCCKColor(71, 70, 73, 1.0);
}

+ (UIColor *)lcck_colorBlackForAddMenuHL {
    return LCCKColor(65, 64, 67, 1.0);
}

@end
