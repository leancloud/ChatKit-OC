//
//  NSBundle+LCCKExtension.m
//  ChatKit
//
//  v0.6.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
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
