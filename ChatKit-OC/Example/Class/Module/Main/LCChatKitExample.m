//
//  LCChatKitExample.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import "LCChatKit.h"
#import "LCChatKitExample.h"
#import "LCCKUtil.h"
#import "NSObject+LCCKHUD.h"
#import "LCCKTabBarControllerConfig.h"
#import "LCCKUser.h"
#import "LCCKConversationViewController.h"
#import "MWPhotoBrowser.h"
#import <objc/runtime.h>

//==================================================================================================================================
//If you want to see the storage of this demo, log in public account of leancloud.cn, search for the app named `LeanCloudChatKit-iOS`.
//======================================== username : leancloud@163.com , password : Public123 =====================================
//==================================================================================================================================

#warning TODO: CHANGE TO YOUR AppId and AppKey
static NSString *const LCCKAPPID = @"wxNCX4GW8kgpJ1h02pa8G248-9Nh9j0Va";
static NSString *const LCCKAPPKEY = @"xzt3UWN6s8geQ5GJWiwpBhXf";

// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@interface LCChatKitExample () <MWPhotoBrowserDelegate>

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, strong) NSMutableArray *selections;

@end

@implementation LCChatKitExample

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


#pragma mark - SDK Life Control

+ (void)invokeThisMethodInDidFinishLaunching {
    [AVOSCloud registerForRemoteNotification];
//    [AVOSCloud setStorageType:AVStorageTypeQCloud];
    [AVIMClient setTimeoutIntervalInSeconds:20];
    [[self sharedInstance] exampleInit];
}

+ (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)invokeThisMethodBeforeLogoutSuccess:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed {
    //    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
    [[LCChatKit sharedInstance] removeAllCachedProfiles];
    [[LCChatKit sharedInstance] removeAllCachedRecentConversations];
    [[LCChatKit sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        CGFloat seconds = arc4random_uniform(4)+arc4random_uniform(4); //normal distribution
        NSLog(@"sleeping fetch of completions for %f", seconds);
        sleep(seconds);
        
        if (succeeded) {
            [LCCKUtil showNotificationWithTitle:@"退出成功" subtitle:nil type:LCCKMessageNotificationTypeSuccess];
            !success ?: success();
        } else {
            [LCCKUtil showNotificationWithTitle:@"退出失败" subtitle:nil type:LCCKMessageNotificationTypeError];
            !failed ?: failed(error);
        }
    }];
}

+ (void)invokeThisMethodAfterLoginSuccessWithClientId:(NSString *)clientId success:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed  {
    [[LCChatKit sharedInstance] openWithClientId:clientId callback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSString *subtitle = [NSString stringWithFormat:@"User Id 是 : %@", clientId];
            [LCCKUtil showNotificationWithTitle:@"登陆成功" subtitle:subtitle type:LCCKMessageNotificationTypeSuccess];
            !success ?: success();
        } else {
            [LCCKUtil showNotificationWithTitle:@"登陆失败" subtitle:nil type:LCCKMessageNotificationTypeError];
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
#ifndef __OPTIMIZE__
    [LCChatKit setAllLogsEnabled:YES];
#endif
    [LCChatKit setAppId:LCCKAPPID appKey:LCCKAPPKEY];
    [[LCChatKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCCKFetchProfilesCallBack callback) {
        if (userIds.count == 0) {
            NSInteger code = 0;
            NSString *errorReasonText = @"User ids is nil";
            NSDictionary *errorInfo = @{
                                        @"code":@(code),
                                        NSLocalizedDescriptionKey : errorReasonText,
                                        };
            NSError *error = [NSError errorWithDomain:@"LCChatKit"
                                                 code:code
                                             userInfo:errorInfo];
            !callback ?: callback(nil, error);
            return;
        }
        
        NSMutableArray *users = [NSMutableArray arrayWithCapacity:userIds.count];;
        for (NSDictionary *user in LCCKContactProfiles) {
            if ([userIds containsObject:user[LCCKProfileKeyPeerId]]) {
                NSURL *avatorURL = [NSURL URLWithString:user[LCCKProfileKeyAvatarURL]];
                LCCKUser *user_ = [[LCCKUser alloc] initWithUserId:user[LCCKProfileKeyPeerId] name:user[LCCKProfileKeyName] avatorURL:avatorURL];
                [users addObject:user_];
            }
        }
        !callback ?: callback([users copy], nil);
    }];
    
    [[LCChatKit sharedInstance] setDidSelectItemBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
        [[self class] exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId fromNavigationController:nil];
    }];
    
    [[LCChatKit sharedInstance] setPreviewImageMessageBlock:^(NSUInteger index, NSArray *imageMessagesInfo, NSDictionary *userInfo) {
        [self examplePreviewImageMessageWithIndex:index imageMessages:imageMessagesInfo];
    }];
    
    //    [[LCChatKit sharedInstance] setDidDeleteItemBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
    //        //TODO:
    //    }];
    
    [[LCChatKit sharedInstance] setOpenProfileBlock:^(NSString *userId, UIViewController *parentController) {
        [self exampleOpenProfileForUserId:userId];
    }];
    
    [[LCChatKit sharedInstance] setAvatarImageViewCornerRadiusBlock:^CGFloat(CGSize avatarImageViewSize) {
        if (avatarImageViewSize.height > 0) {
            return avatarImageViewSize.height/2;
        }
        return 5;
    }];
    
    [[LCChatKit sharedInstance] setShowNotificationBlock:^(UIViewController *viewController, NSString *title, NSString *subtitle, LCCKMessageNotificationType type) {
        [self exampleShowNotificationWithTitle:title subtitle:subtitle type:type];
    }];
    
    // 自定义Cell菜单
    [[LCChatKit sharedInstance] setConversationEditActionBlock:^NSArray *(NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
        return [self exampleConversationEditActionAtIndexPath:indexPath conversation:conversation controller:controller];
    }];
    
    [[LCChatKit sharedInstance] setMarkBadgeWithTotalUnreadCountBlock:^(NSInteger totalUnreadCount, UIViewController *controller) {
        [self exampleMarkBadgeWithTotalUnreadCount:totalUnreadCount controller:controller];
    }];
    
    [[LCChatKit sharedInstance] setPreviewLocationMessageBlock:^(CLLocation *location, NSString *geolocations, NSDictionary *userInfo) {
        [self examplePreViewLocationMessageWithLocation:location geolocations:geolocations];
    }];
    
    [[LCChatKit sharedInstance] setSessionNotOpenedHandler:^(UIViewController *viewController, LCCKBooleanResultBlock callback) {
        [[self class] showMessage:@"正在重新连接聊天服务..." toView:viewController.view];
        [[LCChatKit sharedInstance] openWithClientId:[LCChatKit sharedInstance].clientId callback:^(BOOL succeeded, NSError *error) {
            [[self class] hideHUDForView:viewController.view];
            if (succeeded) {
                [[self class] showSuccess:@"连接成功"];
                callback(succeeded, nil);
            } else {
                [[self class] showError:@"连接失败"];
                callback(succeeded, error);
            }
        }];
    }];
}

- (NSArray *)exampleConversationEditActionAtIndexPath:(NSIndexPath *)indexPath
                                         conversation:(AVIMConversation *)conversation
                                           controller:(LCCKConversationListViewController *)controller {
    // 如果需要自定义其他会话的菜单，在此编辑
    return [self rightButtonsAtIndexPath:indexPath conversation:conversation controller:controller];
}

typedef void (^UITableViewRowActionHandler)(UITableViewRowAction *action, NSIndexPath *indexPath);

- (void)markReadStatusAtIndexPath:(NSIndexPath *)indexPath
                            title:(NSString **)title
                           handle:(UITableViewRowActionHandler *)handler
                     conversation:(AVIMConversation *)conversation
                       controller:(LCCKConversationListViewController *)controller {
    if (conversation.lcim_unreadCount > 0) {
        if (*title == nil) {
            *title = @"标记为已读";
        }
        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [controller.tableView setEditing:NO animated:YES];
            [[LCChatKit sharedInstance] updateUnreadCountToZeroWithConversation:conversation];
            [controller refresh];
        };
    } else {
        if (*title == nil) {
            *title = @"标记为未读";
        }
        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [controller.tableView setEditing:NO animated:YES];
            [[LCChatKit sharedInstance] increaseUnreadCountWithConversation:conversation];
            [controller refresh];
        };
    }
}

- (NSArray *)rightButtonsAtIndexPath:(NSIndexPath *)indexPath
                        conversation:(AVIMConversation *)conversation
                          controller:(LCCKConversationListViewController *)controller {
    NSString *title = nil;
    UITableViewRowActionHandler handler = nil;
    [self markReadStatusAtIndexPath:indexPath
                              title:&title
                             handle:&handler
                       conversation:conversation
                         controller:controller];
    UITableViewRowAction *actionItemMore = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                              title:title
                                                                            handler:handler];
    
    actionItemMore.backgroundColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0];
    
    UITableViewRowAction *actionItemDelete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                                title:@"Delete"
                                                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                                  [[LCChatKit sharedInstance] deleteRecentConversation:conversation];
                                                                                  [controller refresh];
                                                                              }];
    return @[ actionItemDelete, actionItemMore ];
}

#pragma -
#pragma mark - Other Method

/**
 *  打开单聊页面
 */
+ (void)exampleOpenConversationViewControllerWithPeerId:(NSString *)peerId fromNavigationController:(UINavigationController *)navigationController {
    LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithPeerId:peerId];
    [conversationViewController setViewDidLoadBlock:^(LCCKBaseViewController *viewController) {
        [self showMessage:@"加载历史记录..."];
        [viewController configureBarButtonItemStyle:LCCKBarButtonItemStyleSingleProfile action:^{
            NSString *title = @"打开用户详情";
            NSString *subTitle = [NSString stringWithFormat:@"用户id：%@", peerId];
            [LCCKUtil showNotificationWithTitle:title subtitle:subTitle type:LCCKMessageNotificationTypeMessage];
        }];
    }];
    [conversationViewController setConversationHandler:^(AVIMConversation *conversation, LCCKConversationViewController *aConversationController) {
        if (!conversation) {
            [aConversationController.navigationController popViewControllerAnimated:YES];
            return;
        }
    }];
    [conversationViewController setLoadHistoryMessagesHandler:^(BOOL succeeded, NSError *error) {
        [self hideHUD];
        NSString *title;
        LCCKMessageNotificationType type;
        if (succeeded) {
            title = @"聊天记录加载成功";
            type = LCCKMessageNotificationTypeSuccess;
        } else {
            title = @"聊天记录加载失败";
            type = LCCKMessageNotificationTypeError;
        }
        [LCCKUtil showNotificationWithTitle:title subtitle:nil type:type];
    }];
    [self pushToViewController:conversationViewController];
}

+ (void)exampleOpenConversationViewControllerWithConversaionId:(NSString *)conversationId fromNavigationController:(UINavigationController *)aNavigationController {
    LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversationId];
    [conversationViewController setConversationHandler:^(AVIMConversation *conversation, LCCKConversationViewController *aConversationController) {
        if (!conversation) {
            [aConversationController.navigationController popViewControllerAnimated:YES];
            return;
        }
        if (conversation.members.count > 2) {
            [aConversationController configureBarButtonItemStyle:LCCKBarButtonItemStyleGroupProfile action:^{
                NSString *title = @"打开群聊详情";
                NSString *subTitle = [NSString stringWithFormat:@"群聊id：%@", conversationId];
                [LCCKUtil showNotificationWithTitle:title subtitle:subTitle type:LCCKMessageNotificationTypeMessage];
            }];
        } else {
            [aConversationController configureBarButtonItemStyle:LCCKBarButtonItemStyleSingleProfile action:^{
                NSString *title = @"打开用户详情";
                NSString *subTitle = [NSString stringWithFormat:@"单聊id：%@", conversationId];
                [LCCKUtil showNotificationWithTitle:title subtitle:subTitle type:LCCKMessageNotificationTypeMessage];
            }];
        }
        
        if (conversation.members.count > 2 && (![conversation.members containsObject:[LCChatKit sharedInstance].clientId])) {
            [self showMessage:@"正在加入聊天室..."];
            [conversation joinWithCallback:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                NSString *title;
                NSString *subtitle;
                LCCKMessageNotificationType type;
                if (error) {
                    title = @"加入聊天室失败";
                    subtitle = error.localizedDescription;
                    type = LCCKMessageNotificationTypeError;
                    [aConversationController.navigationController popViewControllerAnimated:YES];
                } else {
                    title = @"加入聊天室";
                    type = LCCKMessageNotificationTypeSuccess;
                }
                [LCCKUtil showNotificationWithTitle:title subtitle:subtitle type:type];
            }];
        }
    }];
    
    [conversationViewController setViewDidLoadBlock:^(LCCKBaseViewController *viewController) {
        [self showMessage:@"加载历史记录..."];
    }];
    [conversationViewController setLoadHistoryMessagesHandler:^(BOOL succeeded, NSError *error) {
        [self hideHUD];
        NSString *title;
        LCCKMessageNotificationType type;
        if (succeeded) {
            title = @"聊天记录加载成功";
            type = LCCKMessageNotificationTypeSuccess;
        } else {
            title = @"聊天记录加载失败";
            type = LCCKMessageNotificationTypeError;
        }
        [LCCKUtil showNotificationWithTitle:title subtitle:nil type:type];
    }];
    
    [conversationViewController setViewWillDisappearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
        [self hideHUD];
    }];
    [self pushToViewController:conversationViewController];
}

+ (void)pushToViewController:(UIViewController *)viewController {
    UITabBarController *tabBarController = [self cyl_tabBarController];
    UINavigationController *navigationController = tabBarController.selectedViewController;
    [navigationController cyl_popSelectTabBarChildViewControllerAtIndex:0
                                                             completion:^(__kindof UIViewController *selectedChildTabBarController) {
                                                                 [selectedChildTabBarController.navigationController pushViewController:viewController animated:YES];
                                                             }];
}

- (void)exampleMarkBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount controller:(UIViewController *)controller {
    if (totalUnreadCount > 0) {
        [controller tabBarItem].badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUnreadCount];
    } else {
        [controller tabBarItem].badgeValue = nil;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
}

- (void)examplePreViewLocationMessageWithLocation:(CLLocation *)location geolocations:(NSString *)geolocations {
    NSString *title = [NSString stringWithFormat:@"打开地理位置：%@", geolocations];
    NSString *subTitle = [NSString stringWithFormat:@"纬度：%@\n经度：%@",@(location.coordinate.latitude), @(location.coordinate.longitude)];
    [LCCKUtil showNotificationWithTitle:title subtitle:subTitle type:LCCKMessageNotificationTypeMessage];
}

- (void)examplePreviewImageMessageWithIndex:(NSUInteger)index imageMessages:(NSArray *)imageMessageInfo {
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] initWithCapacity:[imageMessageInfo count]];
    NSMutableArray *thumbs = [[NSMutableArray alloc] initWithCapacity:[imageMessageInfo count]];
    MWPhoto *photo;
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = YES;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    for (id image in imageMessageInfo) {
        if ([image isKindOfClass:[UIImage class]]) {
            // Photos
            photo = [MWPhoto photoWithImage:image];
            [photos addObject:photo];
            [thumbs addObject:photo];
        } else {
            photo = [MWPhoto photoWithURL:image];
            [photos addObject:photo];
            [thumbs addObject:photo];
        }
    }
    // Options
    startOnGrid = NO;
    displayNavArrows = YES;
    self.photos = photos;
    self.thumbs = thumbs;
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.displaySelectionButtons = displaySelectionButtons;
    browser.alwaysShowControls = displaySelectionButtons;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid = enableGrid;
    browser.startOnGrid = startOnGrid;
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = autoPlayOnAppear;
    [browser setCurrentPhotoIndex:index];
    // Reset selections
    if (displaySelectionButtons) {
        _selections = [[NSMutableArray alloc] initWithCapacity:[imageMessageInfo count]];;
        for (int i = 0; i < photos.count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    [[self class] pushToViewController:browser];
}

- (void)exampleOpenProfileForUserId:(NSString *)userId {
    NSString *subtitle = [NSString stringWithFormat:@"User Id 是 : %@", userId];
    [LCCKUtil showNotificationWithTitle:@"打开用户主页" subtitle:subtitle type:LCCKMessageNotificationTypeMessage];
}

- (void)exampleShowNotificationWithTitle:(NSString *)title subtitle:(NSString *)subtitle type:(LCCKMessageNotificationType)type {
    [LCCKUtil showNotificationWithTitle:title subtitle:subtitle type:type];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
    return [_photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
    return [_thumbs objectAtIndex:index];
    return nil;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
}

@end
