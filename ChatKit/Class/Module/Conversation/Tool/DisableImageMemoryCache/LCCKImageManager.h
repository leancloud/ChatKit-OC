//
//  LCCKImageManager.h
//  Kuber
//
//  v0.7.0 Created by Kuber on 16/3/30.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface LCCKImageManager : NSObject

+ (instancetype)defaultManager;

- (UIImage *)getImageWithName:(NSString *)name;
- (UIImage *)getImageWithName:(NSString *)name inBundle:(NSBundle *)bundle;

@end
