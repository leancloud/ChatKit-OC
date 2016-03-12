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
        [AVUser logInWithUsername:@"ElonChan" password:@"123123" error:&error];
        [LCIMUtil hideProgress];
        if (error) {
            NSLog(@"%@",error);
        } else  {
            [[NSUserDefaults standardUserDefaults] setObject:@"ElonChan" forKey:LCIM_KEY_USERNAME];
            break;
        }
    } while (NO);
    [LCIMUtil showProgressText:@"open client ..." duration:10.0f];
    [LCIMKitExample invokeThisMethodAfterLoginSuccessWithClientId:[AVUser currentUser].objectId success:^{
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
