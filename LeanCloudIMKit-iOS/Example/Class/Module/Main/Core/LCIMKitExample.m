//
//  LCIMKitExample.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMKitExample.h"
#import "LCIMUtil.h"
#import "MBProgressHUD+LCIMAddition.h"
#import "LCIMTabBarControllerConfig.h"
#import "LCIMUser.h"
#import "LCIMChatController.h"

//==================================================================================================================================
//If you want to see the storage of this demo, log in public account of leancloud.cn, search for the app named `LeanCloudIMKit-iOS`.
//======================================== username : leancloud@163.com , password : Public123 =====================================
//==================================================================================================================================

#warning TODO: CHANGE TO YOUR AppId and AppKey
//static NSString *const LCIMAPPID = @"ykFkmeXIYRPiK2UfvGWXMWqV-gzGzoHsz";
//static NSString *const LCIMAPPKEY = @"QgVhp43j6puGNQ0sAqNW64uH";
static NSString *const LCIMAPPID = @"x3o016bxnkpyee7e9pa5pre6efx2dadyerdlcez0wbzhw25g";
static NSString *const LCIMAPPKEY = @"057x24cfdzhffnl3dzk14jh9xo2rq6w1hy1fdzt5tv46ym78";

// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@implementation LCIMKitExample

#pragma mark -

+ (void)initialize {
    if (_sharedInstances == nil) {
        _sharedInstances = [NSMutableDictionary dictionary];
    }
}

+ (id)allocWithZone:(NSZone *)zone {
    // Not allow allocating memory in a different zone
    return [self sharedInstance];
}

+ (id)copyWithZone:(NSZone *)zone {
    // Not allow copying to a different zone
    return [self sharedInstance];
}

+ (instancetype)sharedInstance {
    id sharedInstance = nil;
    
    @synchronized(self) {
        NSString *instanceClass = NSStringFromClass(self);
        
        // Looking for existing instance
        sharedInstance = [_sharedInstances objectForKey:instanceClass];
        
        // If there's no instance – create one and add it to the dictionary
        if (sharedInstance == nil) {
            sharedInstance = [[super allocWithZone:nil] init];
            [_sharedInstances setObject:sharedInstance forKey:instanceClass];
        }
    }
    
    return sharedInstance;
}

+ (instancetype)instance {
    return [self sharedInstance];
}

+ (void)destroyInstance {
    [_sharedInstances removeObjectForKey:NSStringFromClass(self)];
}

#pragma mark - SDK Life Control

+ (void)invokeThisMethodInDidFinishLaunching {
    [AVOSCloudIM registerForRemoteNotification];
    [AVIMClient setTimeoutIntervalInSeconds:20];
    [self exampleInit];
}

+ (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)invokeThisMethodBeforeLogout {
    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
    [[LCIMKit sharedInstance] removeAllCachedProfiles];
}

+ (void)invokeThisMethodAfterLoginSuccessWithClientId:(NSString *)clientId success:(LCIMVoidBlock)success failed:(LCIMErrorBlock)failed  {
    [[LCIMKit sharedInstance] openWithClientId:clientId callback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            !success ?: success();
        } else {
            !failed ?: failed(error);
        }
    }];
    //TODO:
}

+ (void)invokeThisMethodInApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateActive) {
        // 应用在前台时收到推送，只能来自于普通的推送，而非离线消息推送
    }
    else {
        //  当使用 https://github.com/leancloud/leanchat-cloudcode 云代码更改推送内容的时候
        //        {
        //            aps =     {
        //                alert = "lcimkit : sdfsdf";
        //                badge = 4;
        //                sound = default;
        //            };
        //            convid = 55bae86300b0efdcbe3e742e;
        //        }
    [[LCIMKit sharedInstance] didReceiveRemoteNotification:userInfo];
    }
}

+ (void)invokeThisMethodInApplicationWillResignActive:(UIApplication *)application {
    [[LCIMSettingService sharedInstance] syncBadge];
}

+ (void)invokeThisMethodInApplicationWillTerminate:(UIApplication *)application {
    [[LCIMSettingService sharedInstance] syncBadge];
}

#pragma -
#pragma mark - LCIMSettingService Method

/**
 *  初始化的示例代码
 */
+ (void)exampleInit {
#ifndef __OPTIMIZE__
    [LCIMKit setAllLogsEnabled:YES];
#endif
    [LCIMKit setAppId:LCIMAPPID appKey:LCIMAPPKEY];
    [[LCIMKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback) {
        if (userIds == 0) {
            NSInteger code = 0;
            NSString *errorReasonText = @"User ids is nil";
            NSDictionary *errorInfo = @{
                                        @"code":@(code),
                                        NSLocalizedDescriptionKey : errorReasonText,
                                        };
            NSError *error = [NSError errorWithDomain:@"LCIMKit"
                                                 code:code
                                             userInfo:errorInfo];
            
            !callback ?: callback(nil, error);
            return;
        }
        
        AVQuery *query = [AVUser query];
        [query setCachePolicy:kAVCachePolicyNetworkElseCache];
        [query whereKey:@"objectId" containedIn:userIds];
        NSError *error;
        NSArray *array = [query findObjects:&error];
        NSMutableArray *users = [NSMutableArray arrayWithCapacity:0];;
        for (AVUser *user in array) {
            // MARK: - add new string named "avatar", custmizing LeanCloud storage
            AVFile *avator = [user objectForKey:@"avatar"];
            NSURL *avatorURL = [NSURL URLWithString:avator.url];
            LCIMUser *user_ = [[LCIMUser alloc] initWithUserId:user.objectId name:user.username avatorURL:avatorURL];
            [users addObject:user_];
        }
        !callback ?: callback([users copy], nil);
        
//        [query findObjectsInBackgroundWithBlock:^(NSArray<AVUser *> *objects, NSError *error) {
//            NSMutableArray *users = [NSMutableArray arrayWithCapacity:0];;
//            for (AVUser *user in objects) {
//                // MARK: - add new string named "avatar", custmizing LeanCloud storage
//                AVFile *avator = [user objectForKey:@"avatar"];
//                NSURL *avatorURL = [NSURL URLWithString:avator.url];
//                LCIMUser *user_ = [[LCIMUser alloc] initWithUserId:user.objectId name:user.username avatorURL:avatorURL];
//                [users addObject:user_];
//            }
//            !callback ?: callback([users copy], nil);
//        }];
    }];
    
    [[LCIMKit sharedInstance] setDidSelectItemBlock:^(AVIMConversation *conversation) {
        [self exampleOpenConversationViewControllerWithConversaion:conversation fromNavigationController:nil];
    }];
}

#pragma -
#pragma mark - Other  Method

/**
 *  打开单聊页面
 */
+ (void)exampleOpenConversationViewControllerWithPeerId:(NSString *)peerId fromNavigationController:(UINavigationController *)navigationController {
    //TODO:
//    [[LCIMConversationService sharedInstance] fecthConversationWithPeerId:peerId callback:^(AVIMConversation *conversation, NSError *error) {
//        [weakSelf exampleOpenConversationViewControllerWithConversaion:conversation fromNavigationController:aNavigationController];
//    }];
    //    AVIMConversation *conversation = [AVIMConversation fetchConversationByPerson:aPerson creatIfNotExist:YES];
//    LCIMConversationViewController *conversaionViewController = [[LCIMConversationViewController alloc] initWithPeerId:peerId];
//    LCIMConversationViewController *conversationController = [[LCIMKit sharedInstance] createConversationViewControllerWithPeerId:peerId];
    LCIMChatController *chatC =[[LCIMChatController alloc] initWithPeerId:peerId];
//    [self.navigationController pushViewController:chatC animated:YES];
    chatC.hidesBottomBarWhenPushed = NO;
    
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    UITabBarController *tabBarController = (UITabBarController *)window.rootViewController;
    UINavigationController *navigationController_ = tabBarController.selectedViewController;
    [navigationController_ pushViewController:chatC animated:YES];
    //    [[LCIMConversationService sharedInstance] openChatWithPeerId:peerId fromController:aNavigationController];
    //    [self exampleOpenConversationViewControllerWithConversation:conversation fromNavigationController:aNavigationController];
}

+ (void)exampleOpenConversationViewControllerWithConversaion:(AVIMConversation *)conversation fromNavigationController:(UINavigationController *)aNavigationController {
    //TODO:
    LCIMChatController *chatC =[[LCIMChatController alloc] initWithConversation:conversation];
    //    [self.navigationController pushViewController:chatC animated:YES];
    chatC.hidesBottomBarWhenPushed = NO;
    
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    UITabBarController *tabBarController = (UITabBarController *)window.rootViewController;
    UINavigationController *navigationController_ = tabBarController.selectedViewController;
    [navigationController_ pushViewController:chatC animated:YES];
    
}

@end
