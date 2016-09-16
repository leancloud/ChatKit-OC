//
//  AppDelegate+RedPacket.m
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/8/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "AppDelegate+RedPacket.h"
#import <objc/runtime.h>
#import "RedpacketOpenConst.h"
#import <AlipaySDK/AlipaySDK.h>

BOOL ClassMethodSwizzle(Class aClass, SEL originalSelector, SEL swizzleSelector) {
    
    Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(aClass, swizzleSelector);
    
    BOOL didAddMethod =
    class_addMethod(aClass,
                    originalSelector,
                    method_getImplementation(swizzleMethod),
                    method_getTypeEncoding(swizzleMethod));
    if (didAddMethod) {
        class_replaceMethod(aClass,
                            swizzleSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    return YES;
}

@implementation AppDelegate (RedPacket)

+ (void)swizzleRedPacketMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ClassMethodSwizzle([self class], @selector(application:openURL:sourceApplication:annotation:), @selector(rp_application:openURL:sourceApplication:annotation:));
        ClassMethodSwizzle([self class], @selector(application:openURL:options:), @selector(rp_application:openURL:options:));
        ClassMethodSwizzle([self class], @selector(applicationDidBecomeActive:), @selector(rp_applicationDidBecomeActive:));
    });
}

// NOTE: 9.0之前使用的API接口
- (BOOL)rp_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RedpacketAlipayNotifaction object:resultDic];
        }];
    }
    return [self rp_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

// NOTE: 9.0以后使用新API接口
- (BOOL)rp_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options{
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RedpacketAlipayNotifaction object:resultDic];
        }];
    }
    return [self rp_application:app openURL:url options:options];
}

- (void)rp_applicationDidBecomeActive:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:RedpacketAlipayNotifaction object:nil];
    [self rp_applicationDidBecomeActive:application];
}

@end
