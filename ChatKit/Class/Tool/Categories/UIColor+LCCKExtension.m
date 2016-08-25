//
//  UIColor+CJ.m
//  LinkLabelDemo
//
//  v0.7.0 Created by CoderJee on 15/4/14.
//  Copyright (c) 2015年 com.huazhi. All rights reserved.
//

#import "UIColor+LCCKExtension.h"

@implementation UIColor (CJ)
+ (UIColor *)CJ_16_Color:(NSString *)code
{
    NSUInteger length = code.length;
    if ((length == 6) || (length == 8))
    {
        unsigned char color[8];
        sscanf(code.UTF8String, "%02X%02X%02X%02X", (unsigned int *)&color[0], (unsigned int *)&color[1], (unsigned int *)&color[2], (unsigned int *)&color[3]);
        if (length == 6)
        {
            color[3] = 0xFF;
        }
        return [UIColor colorWithRed:color[0]/255.0 green:color[1]/255.0 blue:color[2]/255.0 alpha:color[3]/255.0];
    }
    return [UIColor blackColor];
}
@end
