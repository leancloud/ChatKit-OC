//
//  NSBundle+LCCKExtension.h
//  ChatKit
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (LCCKExtension)

+ (NSBundle *)lcck_bundleForName:(NSString *)bundleName class:(Class)aClass;

@end
