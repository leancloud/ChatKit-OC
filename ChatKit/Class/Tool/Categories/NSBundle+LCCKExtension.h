//
//  NSBundle+LCCKExtension.h
//  ChatKit
//
// v0.5.2 Created by 陈宜龙 on 16/5/19.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (LCCKExtension)

+ (NSString *)lcck_bundlePathForBundleName:(NSString *)bundleName class:(Class)aClass;
+ (NSBundle *)lcck_bundleForbundleName:(NSString *)bundleName class:(Class)aClass;

@end
