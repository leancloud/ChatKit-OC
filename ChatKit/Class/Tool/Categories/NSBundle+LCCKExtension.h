//
//  NSBundle+LCCKExtension.h
//  ChatKit
//
//  v0.6.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (LCCKExtension)

+ (NSString *)lcck_bundlePathForBundleName:(NSString *)bundleName class:(Class)aClass;
+ (NSBundle *)lcck_bundleForbundleName:(NSString *)bundleName class:(Class)aClass;

@end
