//
//  UIColor+CJ.h
//  LinkLabelDemo
//
//  v0.7.0 Created by CoderJee on 15/4/14.
//  Copyright (c) 2015年 com.huazhi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (LCCKExtension)
/**
 *  转16进制颜色 不需要转“#”号
 */
+ (UIColor *)CJ_16_Color:(NSString *)code;
@end
