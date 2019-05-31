//
//  NSBundle+LCCKExtension.m
//  ChatKit
//
//  v0.8.5 Created by ElonChan on 16/5/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "NSBundle+LCCKExtension.h"

@implementation NSBundle (LCCKExtension)

+ (NSString *)lcck_bundlePathForBundleName:(NSString *)bundleName class:(Class)aClass {
    NSString *pathComponent = [NSString stringWithFormat:@"%@.bundle", bundleName];
    NSString *bundlePath =[[[NSBundle bundleForClass:aClass] resourcePath] stringByAppendingPathComponent:pathComponent];
    return bundlePath;
}

+ (NSString *)lcck_customizedBundlePathForBundleName:(NSString *)bundleName {
    NSString *customizedBundlePathComponent = [NSString stringWithFormat:@"CustomizedChatKit.%@.bundle", bundleName];
    NSString *customizedBundlePath =[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:customizedBundlePathComponent];
    return customizedBundlePath;
}

+ (NSBundle *)lcck_bundleForName:(NSString *)bundleName class:(Class)aClass {
    NSString *customizedBundlePath = [NSBundle lcck_customizedBundlePathForBundleName:bundleName];
    NSBundle *customizedBundle = [NSBundle bundleWithPath:customizedBundlePath];
    if (customizedBundle) {
        return customizedBundle;
    }
    NSString *bundlePath = [NSBundle lcck_bundlePathForBundleName:bundleName class:aClass];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    return bundle;
}

+ (NSString *) lcck_getLocalizedString:(NSString *)key class:(Class)aClass {
    NSBundle *bundle = [NSBundle lcck_bundleForName:@"Lan" class:aClass];
    return NSLocalizedStringFromTableInBundle(key, nil, bundle, key);
}

@end
