//
//  UIImage+LCCKExtension.h
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/7.
//  Copyright © 2016年 LeanCloud. All rights reserved.
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

- (UIImage *)lcck_scalingPatternImageToSize:(CGSize)size;

@end
