//
//  AppDelegate.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/2.
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

@implementation NSData (GMNSDataHexAdditions)

- (NSString *)gm_hexadecimalEncodedString {
    static const char *hexChars = "0123456789ABCDEF";
    NSUInteger slen = [self length];
    NSUInteger dlen = slen * 2;
    const unsigned char	*src = (const unsigned char *)[self bytes];
    char *dst = (char *)NSZoneMalloc(NSDefaultMallocZone(), dlen);
    NSUInteger spos = 0;
    NSUInteger dpos = 0;
    unsigned char	c;
    while (spos < slen) {
        c = src[spos++];
        dst[dpos++] = hexChars[(c >> 4) & 0x0f];
        dst[dpos++] = hexChars[c & 0x0f];
    }
    NSData *data = [[NSData alloc] initWithBytesNoCopy:dst length:dlen];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    //    [data release];
    return string;
}

@end
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [LCChatKitExample invokeThisMethodInDidFinishLaunching];
    [self customizeNavigationBar];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LCCKLoginViewController *loginViewController = [[LCCKLoginViewController alloc] initWithNibName:@"LCCKLoginViewController" bundle:[NSBundle mainBundle]];
    [loginViewController setClientIDHandler:^(NSString *clientID) {
        [LCCKUtil showProgressText:@"open client ..." duration:10.0f];
        [[NSUserDefaults standardUserDefaults] setObject:clientID forKey:LCCK_KEY_USERID];
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

@end
