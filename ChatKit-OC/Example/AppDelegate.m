//
//  AppDelegate.m
//  LeanCloudChatKit-iOS
//
//  v0.7.15 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "AppDelegate.h"
#import "LCCKTabBarControllerConfig.h"
#import "LCCKConstantsDefinition.h"
#import "LCChatKitExample.h"
#import "LCCKUtil.h"
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#import "LCCKLoginViewController.h"

#if XCODE_VERSION_GREATER_THAN_OR_EQUAL_TO_8
/// Notification become independent from UIKit
@import UserNotifications;
#endif

@interface AppDelegate ()
#if XCODE_VERSION_GREATER_THAN_OR_EQUAL_TO_8
<UNUserNotificationCenterDelegate>
#endif
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [LCChatKitExample invokeThisMethodInDidFinishLaunching];
    [self registerForRemoteNotification];
    [self customizeNavigationBar];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LCCKLoginViewController *loginViewController = [[LCCKLoginViewController alloc] initWithNibName:NSStringFromClass([LCCKLoginViewController class]) bundle:[NSBundle mainBundle]];
    loginViewController.autoLogin = YES;
    [loginViewController setClientIDHandler:^(NSString *clientID) {
        [LCCKUtil showProgressText:@"open client ..." duration:10.0f];
        [LCChatKitExample invokeThisMethodAfterLoginSuccessWithClientId:clientID success:^{
            [LCCKUtil hideProgress];
            LCCKTabBarControllerConfig *tabBarControllerConfig = [[LCCKTabBarControllerConfig alloc] init];
            self.window.rootViewController = tabBarControllerConfig.tabBarController;
        } failed:^(NSError *error) {
            [LCCKUtil hideProgress];
            NSLog(@"%@",error);
        }];
    }];
    
    self.window.rootViewController = loginViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [LCChatKitExample invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)customizeNavigationBar {
    if ([UINavigationBar conformsToProtocol:@protocol(UIAppearanceContainer)]) {
        [UINavigationBar appearance].tintColor = [UIColor whiteColor];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:18], NSForegroundColorAttributeName : [UIColor whiteColor]}];
        [[UINavigationBar appearance] setBarTintColor:NAVIGATION_COLOR];
        [[UINavigationBar appearance] setTranslucent:NO];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [LCChatKitExample invokeThisMethodInApplicationWillResignActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [LCChatKitExample invokeThisMethodInApplicationWillTerminate:application];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [LCChatKitExample invokeThisMethodInApplication:application didReceiveRemoteNotification:userInfo];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return YES;
}

#pragma -
#pragma mark - Other Method

#pragma mark - 初始化UNUserNotificationCenter
///=============================================================================
/// @name 初始化UNUserNotificationCenter
///=============================================================================

/**
 * 初始化UNUserNotificationCenter
 */
- (void)registerForRemoteNotification {
    // iOS 10 兼容
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        
#if XCODE_VERSION_GREATER_THAN_OR_EQUAL_TO_8
        
        // 使用 UNUserNotificationCenter 来管理通知
        UNUserNotificationCenter *uncenter = [UNUserNotificationCenter currentNotificationCenter];
        // 监听回调事件
        [uncenter setDelegate:self];
        //iOS 10 使用以下方法注册，才能得到授权
        [uncenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert+UNAuthorizationOptionBadge+UNAuthorizationOptionSound)
                                completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                    //TODO:授权状态改变
                                    NSLog(@"%@" , granted ? @"授权成功" : @"授权失败");
                                }];
        // 获取当前的通知授权状态, UNNotificationSettings
        [uncenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            NSLog(@"%s\nline:%@\n-----\n%@\n\n", __func__, @(__LINE__), settings);
            /*
             UNAuthorizationStatusNotDetermined : 没有做出选择
             UNAuthorizationStatusDenied : 用户未授权
             UNAuthorizationStatusAuthorized ：用户已授权
             */
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                NSLog(@"未选择");
            } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                NSLog(@"未授权");
            } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                NSLog(@"已授权");
            }
        }];
        
#endif
        
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIUserNotificationType types = UIUserNotificationTypeAlert |
        UIUserNotificationTypeBadge |
        UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UIRemoteNotificationType types = UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeAlert |
        UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
    }
#pragma clang diagnostic pop
}

@end
