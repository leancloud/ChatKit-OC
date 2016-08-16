//
//  NSBundle+LCCKExtension.m
//  ChatKit
//
// v0.5.2 Created by 陈宜龙 on 16/5/19.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "NSBundle+LCCKExtension.h"

@implementation NSBundle (LCCKExtension)

+ (NSString *)lcck_bundlePathForBundleName:(NSString *)bundleName class:(Class)aClass {
    NSString *pathComponent = [NSString stringWithFormat:@"%@.bundle", bundleName];
    NSString *bundlePath =[[[NSBundle bundleForClass:aClass] resourcePath] stringByAppendingPathComponent:pathComponent];
    return bundlePath;
}

+ (NSBundle *)lcck_bundleForbundleName:(NSString *)bundleName class:(Class)aClass {
    NSString *bundlePath = [NSBundle lcck_bundlePathForBundleName:bundleName class:aClass];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    return bundle;
}

@end
