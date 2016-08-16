//
//  UIImage+LCCKExtension.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/5/7.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSBundle+LCCKExtension.h"

@interface UIImage (LCCKExtension)

- (UIImage *)lcck_imageByScalingAspectFill;
/*!
 * @attention This will invoke `CGSize kMaxImageViewSize = {.width = 200, .height = 200};`.
 */
- (UIImage *)lcck_imageByScalingAspectFillWithOriginSize:(CGSize)originSize;

- (UIImage *)lcck_imageByScalingAspectFillWithOriginSize:(CGSize)originSize
                                               limitSize:(CGSize)limitSize;

+ (UIImage *)lcck_imageNamed:(NSString *)imageName bundleName:(NSString *)bundleName bundleForClass:(Class)aClass;
+ (UIImage *)lcck_imageNamed:(NSString *)name;

@end
