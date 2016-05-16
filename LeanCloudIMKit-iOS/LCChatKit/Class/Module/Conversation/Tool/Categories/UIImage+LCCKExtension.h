//
//  UIImage+LCCKExtension.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/5/7.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LCCKExtension)

- (UIImage *)lcck_imageByScalingAspectFill;
/*!
 * @attention This will invoke `CGSize kMaxImageViewSize = {.width = 200, .height = 200};`.
 */
- (UIImage *)lcck_imageByScalingAspectFillWithOriginSize:(CGSize)originSize;

- (UIImage *)lcck_imageByScalingAspectFillWithOriginSize:(CGSize)originSize
                                               limitSize:(CGSize)limitSize;

@end
