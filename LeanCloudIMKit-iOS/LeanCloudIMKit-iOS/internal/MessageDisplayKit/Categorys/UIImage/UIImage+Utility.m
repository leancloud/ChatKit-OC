//
//  UIImage+Utility.m
//  XHImageViewer
//
//  Created by 曾 宪华 on 14-2-18.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "UIImage+Utility.h"

@implementation UIImage (Utility)

+ (UIImage *)lcim_decode:(UIImage *)image {
    if(image == nil) {
        return nil;
    }
    
    UIGraphicsBeginImageContext(image.size);
    
    {
        [image drawAtPoint:CGPointMake(0, 0)];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)lcim_fastImageWithData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    return [self lcim_decode:image];
}

+ (UIImage *)lcim_fastImageWithContentsOfFile:(NSString *)path {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    return [self lcim_decode:image];
}

@end
