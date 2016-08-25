//
//  NSBundle+LCCKSCaleArray.m
//  Kuber
//
//  v0.7.0 Created by Kuber on 16/3/30.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import "NSBundle+LCCKSCaleArray.h"
#import <UIKit/UIKit.h>

@implementation NSBundle (LCCKSCaleArray)

+ (NSArray *)lcck_scaleArray {
    static NSArray *scales;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat screenScale = [UIScreen mainScreen].scale;
        if (screenScale <= 1) {
            scales = @[ @1,@2,@3 ];
        } else if (screenScale <= 2) {
            scales = @[ @2,@3,@1 ];
        } else {
            scales = @[ @3,@2,@1 ];
        }
    });
    return scales;
}

@end
