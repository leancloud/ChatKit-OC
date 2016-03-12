//
//  UIImage+Utility.h
//  XHImageViewer
//
//  Created by 曾 宪华 on 14-2-18.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utility)
+ (UIImage *)lcim_fastImageWithData:(NSData *)data;
+ (UIImage *)lcim_fastImageWithContentsOfFile:(NSString *)path;
@end
