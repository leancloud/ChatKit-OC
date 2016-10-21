//
//  LCChatKitExample.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKTabBarControllerConfig.h"
#import "LCCKUser.h"
#import "LCCKUtil.h"
#import "LCChatKitExample.h"

#import "NSObject+LCCKHUD.h"
#import <objc/runtime.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#import "LCCKContactManager.h"
#import "LCCKExampleConstants.h"
#import "LCCKLoginViewController.h"
#import "LCCKVCardMessageCell.h"

#import "LCChatKitExample+Setting.h"
#import "RedpacketConfig.h"

@interface LCChatKitExample ()

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, strong) NSMutableArray *selections;

@end

@implementation LCChatKitExample

#pragma mark - SDK Life Control

+ (void)invokeThisMethodInDidFinishLaunching {
    // 如果APP是在国外使用，开启北美节点
    // [AVOSCloud setServiceRegion:AVServiceRegionUS];
    // 启用未读消息
    [AVIMClient setUserOptions:@{ AVIMUserOptionUseUnread : @(YES) }];
    [AVIMClient setTimeoutIntervalInSeconds:20];
    //添加输入框底部插件，如需更换图标标题，可子类化，然后调用 `+registerSubclass`
    [LCCKInputViewPluginTakePhoto registerSubclass];
    [LCCKInputViewPluginPickImage registerSubclass];
    [LCCKInputViewPluginLocation registerSubclass];
    [[RedpacketConfig sharedConfig] lcck_setting];
}

+ (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)invokeThisMethodBeforeLogoutSuccess:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed {
    //    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
    [[LCChatKit sharedInstance] removeAllCachedProfiles];
    [[LCChatKit sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self lcck_clearLocalClientInfo];
            [LCCKUtil showNotificationWithTitle:@"退出成功"
                                       subtitle:nil
                                           type:LCCKMessageNotificationTypeSuccess];
            !success ?: success();
        } else {
            [LCCKUtil showNotificationWithTitle:@"退出失败"
                                       subtitle:nil
                                           type:LCCKMessageNotificationTypeError];
            !failed ?: failed(error);
        }
    }];
}

+ (void)invokeThisMethodAfterLoginSuccessWithClientId:(NSString *)clientId
                                              success:(LCCKVoidBlock)success
                                               failed:(LCCKErrorBlock)failed {
    [[self sharedInstance] exampleInit];
    [[LCChatKit sharedInstance] openWithClientId:clientId
                                        callback:^(BOOL succeeded, NSError *error) {
                                            if (succeeded) {
                                                [self saveLocalClientInfo:clientId];
                                                [[RedpacketConfig sharedConfig] lcck_setting];
                                                !success ?: success();
                                            } else {
                                                [LCCKUtil showNotificationWithTitle:@"登陆失败"
                                                                           subtitle:nil
                                                                               type:LCCKMessageNotificationTypeError];
                                                !failed ?: failed(error);
                                            }
                                        }];
    // TODO:
}

+ (void)invokeThisMethodInApplication:(UIApplication *)application
         didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (application.applicationState == UIApplicationStateActive) {
        // 应用在前台时收到推送，只能来自于普通的推送，而非离线消息推送
    } else {
        /*!
         *  当使用 https://github.com/leancloud/leanchat-cloudcode 云代码更改推送内容的时候
         {
         aps = {
                alert = "lcckkit : sdfsdf";
                badge = 4;
                sound = default;
            };
          convid = 55bae86300b0efdcbe3e742e;
         }
         */
        [[LCChatKit sharedInstance] didReceiveRemoteNotification:userInfo];
    }
}

+ (void)invokeThisMethodInApplicationWillResignActive:(UIApplication *)application {
    [[LCChatKit sharedInstance] syncBadge];
}

+ (void)invokeThisMethodInApplicationWillTerminate:(UIApplication *)application {
    [[LCChatKit sharedInstance] syncBadge];
}

#pragma -
#pragma mark - init Method

/**
 *  初始化的示例代码
 */
- (void)exampleInit {
    [self lcck_setting];
    [[RedpacketConfig sharedConfig] lcck_setting];

}

#pragma -
#pragma mark - Other Method

+ (void)exampleChangeGroupAvatarURLsForConversationId:(NSString *)conversationId {
    [self lcck_exampleChangeGroupAvatarURLsForConversationId:conversationId shouldInsert:YES];
}

+ (void)exampleCreateGroupConversationFromViewController:(UIViewController *)fromViewController {
    // FIXME: add more to allPersonIds
    NSArray *allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
    NSArray *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:allPersonIds
                                                           shouldSameCount:YES
                                                                     error:nil];
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    LCCKContactListViewController *contactListViewController =
    [[LCCKContactListViewController alloc]
     initWithContacts:[NSSet setWithArray:users]
     userIds:[NSSet setWithArray:allPersonIds]
     excludedUserIds:[NSSet setWithArray:@[ currentClientID ]]
     mode:LCCKContactListModeMultipleSelection];
    contactListViewController.title = @"创建群聊";
    [contactListViewController setSelectedContactsCallback:^(UIViewController *viewController,
                                                             NSArray<NSString *> *peerIds) {
        if (!peerIds || peerIds.count == 0) {
            return;
        }
        [self lcck_showMessage:@"创建群聊..." toView:fromViewController.view];
        [[LCChatKit sharedInstance]
         createConversationWithMembers:peerIds
         type:LCCKConversationTypeGroup
         unique:YES
         callback:^(AVIMConversation *conversation, NSError *error) {
             [self lcck_hideHUDForView:fromViewController.view];
             if (conversation) {
                 [self lcck_showSuccess:@"创建成功"
                                 toView:fromViewController.view];
                 [self
                  exampleOpenConversationViewControllerWithConversaionId:
                  conversation.conversationId
                  fromNavigationController:
                  viewController
                  .navigationController];
             } else {
                 [self lcck_showError:@"创建失败"
                               toView:fromViewController.view];
             }
         }];
    }];
    UINavigationController *navigationViewController =
    [[UINavigationController alloc] initWithRootViewController:contactListViewController];
    [fromViewController presentViewController:navigationViewController animated:YES completion:nil];
}

/**
 *  打开单聊页面
 */
+ (void)exampleOpenConversationViewControllerWithPeerId:(NSString *)peerId
                               fromNavigationController:(UINavigationController *)navigationControlle {

    LCCKConversationViewController *conversationViewController =
    [[LCCKConversationViewController alloc] initWithPeerId:peerId];
    [conversationViewController
     setViewWillDisappearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
         [self lcck_hideHUDForView:viewController.view];
     }];
    [self lcck_pushToViewController:conversationViewController];
}

+ (void)exampleOpenConversationViewControllerWithConversaionId:(NSString *)conversationId
                                      fromNavigationController:
(UINavigationController *)aNavigationController {
    LCCKConversationViewController *conversationViewController =
    [[LCCKConversationViewController alloc] initWithConversationId:conversationId];
    conversationViewController.enableAutoJoin = YES;
    [conversationViewController
     setViewWillDisappearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
         [self lcck_hideHUDForView:viewController.view];
     }];
    [conversationViewController
     setViewWillAppearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent
                                                     animated:aAnimated];
     }];
    
    [self lcck_pushToViewController:conversationViewController];
}

+ (void)signOutFromViewController:(UIViewController *)viewController {
    [LCCKUtil showProgressText:@"close client ..." duration:10.0f];
    [LCChatKitExample invokeThisMethodBeforeLogoutSuccess:^{
        [LCCKUtil hideProgress];
        LCCKLoginViewController *loginViewController = [[LCCKLoginViewController alloc] init];
        [loginViewController setClientIDHandler:^(NSString *clientID) {
            [LCChatKitExample invokeThisMethodAfterLoginSuccessWithClientId:clientID
                                                                    success:^{
                                                                        LCCKTabBarControllerConfig *tabBarControllerConfig =
                                                                        [[LCCKTabBarControllerConfig alloc] init];
                                                                        [self cyl_tabBarController].rootWindow.rootViewController =
                                                                        tabBarControllerConfig.tabBarController;
                                                                    }
                                                                     failed:^(NSError *error) {
                                                                         LCCKLog(@"%@", error);
                                                                     }];
        }];
        [viewController presentViewController:loginViewController animated:YES completion:nil];
    }
                                                   failed:^(NSError *error) {
                                                       [LCCKUtil hideProgress];
                                                       LCCKLog(@"%@", error);
                                                   }];
}

- (void)exampleOpenProfileForUser:(id<LCCKUserDelegate>)user
                           userId:(NSString *)userId
                 parentController:(__kindof UIViewController *)parentController {
    NSString *currentClientId = [LCChatKit sharedInstance].clientId;
    NSString *title = [NSString stringWithFormat:@"打开用户主页 \nClientId是 : %@", userId];
    NSString *subtitle = [NSString stringWithFormat:@"name是 : %@", user.name];
    if ([userId isEqualToString:currentClientId]) {
        title = [NSString stringWithFormat:@"打开自己的主页 \nClientId是 : %@", userId];
        subtitle = [NSString stringWithFormat:@"我自己的name是 : %@", user.name];
    
    } else if ([parentController isKindOfClass:[LCCKConversationViewController class]]) {
        LCCKConversationViewController *conversationViewController_ =
        [[LCCKConversationViewController alloc] initWithPeerId:user.clientId ?: userId];
        [[self class] lcck_pushToViewController:conversationViewController_];
        return;
    }
    [LCCKUtil showNotificationWithTitle:title
                               subtitle:subtitle
                                   type:LCCKMessageNotificationTypeMessage];
}

#pragma mark -
#pragma mark - Private Methods

/**
 * create a singleton instance of LCChatKitExample
 */
+ (instancetype)sharedInstance {
    static LCChatKitExample *_sharedLCChatKitExample = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCChatKitExample = [[self alloc] init];
    });
    return _sharedLCChatKitExample;
}

+ (void)saveLocalClientInfo:(NSString *)clientId {
    // 在系统偏好保存信息
    NSUserDefaults *defaultsSet = [NSUserDefaults standardUserDefaults];
    [defaultsSet setObject:clientId forKey:LCCK_KEY_USERID];
    [defaultsSet synchronize];
    NSString *subtitle = [NSString stringWithFormat:@"User Id 是 : %@", clientId];
    [LCCKUtil showNotificationWithTitle:@"登陆成功"
                               subtitle:subtitle
                                   type:LCCKMessageNotificationTypeSuccess];
}

@end
