//
//  UIImage+LCCKExtension.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/5/7.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "UIImage+LCCKExtension.h"


@implementation UIImage (LCCKExtension)

#pragma mark -
#pragma mark - public Methods

- (UIImage *)lcck_imageByScalingAspectFillWithOriginSize:(CGSize)originSize {
    CGSize kMaxImageViewSize = {.width = 200, .height = 200};
    UIImage *resizedImage = [self lcck_imageByScalingAspectFillWithOriginSize:originSize limitSize:kMaxImageViewSize];
    return resizedImage;
}

- (UIImage *)lcck_imageByScalingAspectFillWithOriginSize:(CGSize)originSize
                                           limitSize:(CGSize)limitSize {
    if (originSize.width == 0 || originSize.height == 0) {
        return self;
    }
    CGFloat aspectRatio = originSize.width / originSize.height;
    CGFloat width;
    CGFloat height;
    //胖照片
    if (limitSize.width / aspectRatio <= limitSize.height) {
        width = limitSize.width;
        height = limitSize.width / aspectRatio;
    } else {
        //瘦照片
        width = limitSize.height * aspectRatio;
        height = limitSize.height;
    }
    return [self lcck_scaledToSize:CGSizeMake(width, height)];
}

#pragma mark -
#pragma mark - Private Methods

- (UIImage *)lcck_scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

