//
//  AppDelegate.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "AppDelegate.h"
#import "LCIMTabBarControllerConfig.h"
#import "LCIMConstantsDefinition.h"
#import "LCIMKitExample.h"
#import "LCIMUtil.h"
#import "LCIMKit.h"
#import "LCIMLoginViewController.h"
#import "LCIMConversationViewModel.h"

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
    [LCIMKitExample invokeThisMethodInDidFinishLaunching];
    [self customizeNavigationBar];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LCIMLoginViewController *loginViewController = [[LCIMLoginViewController alloc] initWithNibName:@"LCIMLoginViewController" bundle:[NSBundle mainBundle]];
    [loginViewController setClientIDHandler:^(NSString *clientID) {
        [LCIMUtil showProgressText:@"open client ..." duration:10.0f];
        [[NSUserDefaults standardUserDefaults] setObject:clientID forKey:LCIM_KEY_USERID];
        [LCIMKitExample invokeThisMethodAfterLoginSuccessWithClientId:clientID success:^{
            [LCIMUtil hideProgress];
            LCIMTabBarControllerConfig *tabBarControllerConfig = [[LCIMTabBarControllerConfig alloc] init];
            self.window.rootViewController = tabBarControllerConfig.tabBarController;
        } failed:^(NSError *error) {
            [LCIMUtil hideProgress];
            NSLog(@"%@",error);
        }];
    }];
    self.window.rootViewController = loginViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [LCIMKitExample invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
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
    [LCIMKitExample invokeThisMethodInApplicationWillResignActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [LCIMKitExample invokeThisMethodInApplicationWillTerminate:application];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [LCIMKitExample invokeThisMethodInApplication:application didReceiveRemoteNotification:userInfo];
}

@end
