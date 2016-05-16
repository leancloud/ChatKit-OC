//
//  LCIMKitExample.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import "LCIMKit.h"
#import "LCIMKitExample.h"
#import "LCIMUtil.h"
#import "NSObject+LCCKHUD.h"
#import "LCIMTabBarControllerConfig.h"
#import "LCIMUser.h"
#import "LCIMConversationViewController.h"
#import "MWPhotoBrowser.h"
#import <objc/runtime.h>

//==================================================================================================================================
//If you want to see the storage of this demo, log in public account of leancloud.cn, search for the app named `LeanCloudIMKit-iOS`.
//======================================== username : leancloud@163.com , password : Public123 =====================================
//==================================================================================================================================

#warning TODO: CHANGE TO YOUR AppId and AppKey

static NSString *const LCIMAPPID = @"dYRQ8YfHRiILshUnfFJu2eQM-gzGzoHsz";
static NSString *const LCIMAPPKEY = @"ye24iIK6ys8IvaISMC4Bs5WK";

// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@interface LCIMKitExample () <MWPhotoBrowserDelegate>

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, strong) NSMutableArray *selections;

@end

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

+ (void)invokeThisMethodBeforeLogoutSuccess:(LCIMVoidBlock)success failed:(LCIMErrorBlock)failed {
    //    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
    [[LCIMKit sharedInstance] removeAllCachedProfiles];
    [[LCIMKit sharedInstance] removeAllCachedRecentConversations];
    [[LCIMKit sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
        CGFloat seconds = arc4random_uniform(4)+arc4random_uniform(4); //normal distribution
        NSLog(@"sleeping fetch of completions for %f", seconds);
        sleep(seconds);
        
        if (succeeded) {
            [LCIMUtil showNotificationWithTitle:@"退出成功" subtitle:nil type:LCIMMessageNotificationTypeSuccess];
            !success ?: success();
        } else {
            [LCIMUtil showNotificationWithTitle:@"退出失败" subtitle:nil type:LCIMMessageNotificationTypeError];
            !failed ?: failed(error);
        }
    }];
}

+ (void)invokeThisMethodAfterLoginSuccessWithClientId:(NSString *)clientId success:(LCIMVoidBlock)success failed:(LCIMErrorBlock)failed  {
    [[LCIMKit sharedInstance] openWithClientId:clientId callback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSString *subtitle = [NSString stringWithFormat:@"User Id 是 : %@", clientId];
            [LCIMUtil showNotificationWithTitle:@"登陆成功" subtitle:subtitle type:LCIMMessageNotificationTypeSuccess];
            !success ?: success();
        } else {
            [LCIMUtil showNotificationWithTitle:@"登陆失败" subtitle:nil type:LCIMMessageNotificationTypeError];
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
    [[LCIMKit sharedInstance] syncBadge];
}

+ (void)invokeThisMethodInApplicationWillTerminate:(UIApplication *)application {
    [[LCIMKit sharedInstance] syncBadge];
}

#pragma -
#pragma mark - init Method

/**
 *  初始化的示例代码
 */
- (void)exampleInit {
#ifndef __OPTIMIZE__
    [LCIMKit setAllLogsEnabled:YES];
#endif
    [LCIMKit setAppId:LCIMAPPID appKey:LCIMAPPKEY];
    [[LCIMKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback) {
        if (userIds.count == 0) {
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
        
        NSMutableArray *users = [NSMutableArray arrayWithCapacity:userIds.count];;
        for (NSDictionary *user in LCIMContactProfiles) {
            if ([userIds containsObject:user[LCIMProfileKeyPeerId]]) {
                NSURL *avatorURL = [NSURL URLWithString:user[LCIMProfileKeyAvatarURL]];
                LCIMUser *user_ = [[LCIMUser alloc] initWithUserId:user[LCIMProfileKeyPeerId] name:user[LCIMProfileKeyName] avatorURL:avatorURL];
                [users addObject:user_];
            }
        }
        !callback ?: callback([users copy], nil);
    }];
    
    [[LCIMKit sharedInstance] setDidSelectItemBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCIMConversationListViewController *controller) {
        [[self class] exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId fromNavigationController:nil];
    }];
    
    [[LCIMKit sharedInstance] setPreviewImageMessageBlock:^(NSUInteger index, NSArray *imageMessagesInfo, NSDictionary *userInfo) {
        [self examplePreviewImageMessageWithIndex:index imageMessages:imageMessagesInfo];
    }];
    
    //    [[LCIMKit sharedInstance] setDidDeleteItemBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCIMConversationListViewController *controller) {
    //        //TODO:
    //    }];
    
    [[LCIMKit sharedInstance] setOpenProfileBlock:^(NSString *userId, UIViewController *parentController) {
        [self exampleOpenProfileForUserId:userId];
    }];
    
    [[LCIMKit sharedInstance] setAvatarImageViewCornerRadiusBlock:^CGFloat(CGSize avatarImageViewSize) {
        if (avatarImageViewSize.height > 0) {
            return avatarImageViewSize.height/2;
        }
        return 5;
    }];
    
    [[LCIMKit sharedInstance] setShowNotificationBlock:^(UIViewController *viewController, NSString *title, NSString *subtitle, LCIMMessageNotificationType type) {
        [self exampleShowNotificationWithTitle:title subtitle:subtitle type:type];
    }];
    
    // 自定义Cell菜单
    [[LCIMKit sharedInstance] setConversationEditActionBlock:^NSArray *(NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions, AVIMConversation *conversation, LCIMConversationListViewController *controller) {
        return [self exampleConversationEditActionAtIndexPath:indexPath conversation:conversation controller:controller];
    }];
    
    [[LCIMKit sharedInstance] setMarkBadgeWithTotalUnreadCountBlock:^(NSInteger totalUnreadCount, UIViewController *controller) {
        [self exampleMarkBadgeWithTotalUnreadCount:totalUnreadCount controller:controller];
    }];
    
    [[LCIMKit sharedInstance] setPreviewLocationMessageBlock:^(CLLocation *location, NSString *geolocations, NSDictionary *userInfo) {
        [self examplePreViewLocationMessageWithLocation:location geolocations:geolocations];
    }];
    
    [[LCIMKit sharedInstance] setSessionNotOpenedHandler:^(UIViewController *viewController, LCIMBooleanResultBlock callback) {
        [[self class] showMessage:@"正在重新连接聊天服务..." toView:viewController.view];
        [[LCIMKit sharedInstance] openWithClientId:[LCIMKit sharedInstance].clientId callback:^(BOOL succeeded, NSError *error) {
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
                                           controller:(LCIMConversationListViewController *)controller {
    // 如果需要自定义其他会话的菜单，在此编辑
    return [self rightButtonsAtIndexPath:indexPath conversation:conversation controller:controller];
}

typedef void (^UITableViewRowActionHandler)(UITableViewRowAction *action, NSIndexPath *indexPath);

- (void)markReadStatusAtIndexPath:(NSIndexPath *)indexPath
                            title:(NSString **)title
                           handle:(UITableViewRowActionHandler *)handler
                     conversation:(AVIMConversation *)conversation
                       controller:(LCIMConversationListViewController *)controller {
    if (conversation.lcim_unreadCount > 0) {
        if (*title == nil) {
            *title = @"标记为已读";
        }
        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [controller.tableView setEditing:NO animated:YES];
            [[LCIMKit sharedInstance] updateUnreadCountToZeroWithConversation:conversation];
            [controller refresh];
        };
    } else {
        if (*title == nil) {
            *title = @"标记为未读";
        }
        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [controller.tableView setEditing:NO animated:YES];
            [[LCIMKit sharedInstance] increaseUnreadCountWithConversation:conversation];
            [controller refresh];
        };
    }
}

- (NSArray *)rightButtonsAtIndexPath:(NSIndexPath *)indexPath
                        conversation:(AVIMConversation *)conversation
                          controller:(LCIMConversationListViewController *)controller {
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
                                                                                  [[LCIMKit sharedInstance] deleteRecentConversation:conversation];
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
    LCIMConversationViewController *conversationViewController = [[LCIMConversationViewController alloc] initWithPeerId:peerId];
    [conversationViewController setViewDidLoadBlock:^(LCIMBaseViewController *viewController) {
        [self showMessage:@"加载历史记录..."];
        [viewController configureBarButtonItemStyle:LCIMBarButtonItemStyleSingleProfile action:^{
            NSString *title = @"打开用户详情";
            NSString *subTitle = [NSString stringWithFormat:@"用户id：%@", peerId];
            [LCIMUtil showNotificationWithTitle:title subtitle:subTitle type:LCIMMessageNotificationTypeMessage];
        }];
    }];
    [conversationViewController setConversationHandler:^(AVIMConversation *conversation, LCIMConversationViewController *aConversationController) {
        if (!conversation) {
            [aConversationController.navigationController popViewControllerAnimated:YES];
            return;
        }
    }];
    [conversationViewController setLoadHistoryMessagesHandler:^(BOOL succeeded, NSError *error) {
        [self hideHUD];
        NSString *title;
        LCIMMessageNotificationType type;
        if (succeeded) {
            title = @"聊天记录加载成功";
            type = LCIMMessageNotificationTypeSuccess;
        } else {
            title = @"聊天记录加载失败";
            type = LCIMMessageNotificationTypeError;
        }
        [LCIMUtil showNotificationWithTitle:title subtitle:nil type:type];
    }];
    [self pushToViewController:conversationViewController];
}

+ (void)exampleOpenConversationViewControllerWithConversaionId:(NSString *)conversationId fromNavigationController:(UINavigationController *)aNavigationController {
    LCIMConversationViewController *conversationViewController = [[LCIMConversationViewController alloc] initWithConversationId:conversationId];
    [conversationViewController setConversationHandler:^(AVIMConversation *conversation, LCIMConversationViewController *aConversationController) {
        if (!conversation) {
            [aConversationController.navigationController popViewControllerAnimated:YES];
            return;
        }
        if (conversation.members.count > 2) {
            [aConversationController configureBarButtonItemStyle:LCIMBarButtonItemStyleGroupProfile action:^{
                NSString *title = @"打开群聊详情";
                NSString *subTitle = [NSString stringWithFormat:@"群聊id：%@", conversationId];
                [LCIMUtil showNotificationWithTitle:title subtitle:subTitle type:LCIMMessageNotificationTypeMessage];
            }];
        } else {
            [aConversationController configureBarButtonItemStyle:LCIMBarButtonItemStyleSingleProfile action:^{
                NSString *title = @"打开用户详情";
                NSString *subTitle = [NSString stringWithFormat:@"单聊id：%@", conversationId];
                [LCIMUtil showNotificationWithTitle:title subtitle:subTitle type:LCIMMessageNotificationTypeMessage];
            }];
        }
        
        if (conversation.members.count > 2 && (![conversation.members containsObject:[LCIMKit sharedInstance].clientId])) {
            [self showMessage:@"正在加入聊天室..."];
            [conversation joinWithCallback:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                NSString *title;
                NSString *subtitle;
                LCIMMessageNotificationType type;
                if (error) {
                    title = @"加入聊天室失败";
                    subtitle = error.localizedDescription;
                    type = LCIMMessageNotificationTypeError;
                    [aConversationController.navigationController popViewControllerAnimated:YES];
                } else {
                    title = @"加入聊天室";
                    type = LCIMMessageNotificationTypeSuccess;
                }
                [LCIMUtil showNotificationWithTitle:title subtitle:subtitle type:type];
            }];
        }
    }];
    
    [conversationViewController setViewDidLoadBlock:^(LCIMBaseViewController *viewController) {
        [self showMessage:@"加载历史记录..."];
    }];
    [conversationViewController setLoadHistoryMessagesHandler:^(BOOL succeeded, NSError *error) {
        [self hideHUD];
        NSString *title;
        LCIMMessageNotificationType type;
        if (succeeded) {
            title = @"聊天记录加载成功";
            type = LCIMMessageNotificationTypeSuccess;
        } else {
            title = @"聊天记录加载失败";
            type = LCIMMessageNotificationTypeError;
        }
        [LCIMUtil showNotificationWithTitle:title subtitle:nil type:type];
    }];
    
    [conversationViewController setViewWillDisappearBlock:^(LCIMBaseViewController *viewController, BOOL aAnimated) {
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
    [LCIMUtil showNotificationWithTitle:title subtitle:subTitle type:LCIMMessageNotificationTypeMessage];
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
    [LCIMUtil showNotificationWithTitle:@"打开用户主页" subtitle:subtitle type:LCIMMessageNotificationTypeMessage];
}

- (void)exampleShowNotificationWithTitle:(NSString *)title subtitle:(NSString *)subtitle type:(LCIMMessageNotificationType)type {
    [LCIMUtil showNotificationWithTitle:title subtitle:subtitle type:type];
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
