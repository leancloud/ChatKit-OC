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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [LCIMKitExample invokeThisMethodInDidFinishLaunching];
    [self customizeNavigationBar];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [self logIn];
    return YES;
}

- (void)logIn {
    do {
        /* If already loged in, break. */
        if ([AVUser currentUser]) {
            break;
        }
        /* If not loged in, log in. */
        [LCIMUtil showProgressText:@"log in ..." duration:10.0f];
        NSError *error = nil;
        [AVUser logInWithUsername:@"imkittest" password:@"123456" error:&error];
        [LCIMUtil hideProgress];
        if (error) {
            NSLog(@"%@",error);
        } else  {
            [[NSUserDefaults standardUserDefaults] setObject:@"imkittest" forKey:LCIM_KEY_USERNAME];
            break;
        }
    } while (NO);
    [LCIMUtil showProgressText:@"open client ..." duration:10.0f];
    [LCIMKitExample invokeThisMethodAfterLoginSuccessWithClientId:@"imkittest" success:^{
        [LCIMUtil hideProgress];
        LCIMTabBarControllerConfig *tabBarControllerConfig = [[LCIMTabBarControllerConfig alloc] init];
        self.window.rootViewController = tabBarControllerConfig.tabBarController;
    } failed:^(NSError *error) {
        [LCIMUtil hideProgress];
        NSLog(@"%@",error);
    }];
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

@end
