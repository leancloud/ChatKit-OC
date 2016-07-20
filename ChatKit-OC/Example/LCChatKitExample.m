//
//  LCChatKitExample.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import "LCChatKitExample.h"
#import "LCCKUtil.h"
#import "NSObject+LCCKHUD.h"
#import "LCCKTabBarControllerConfig.h"
#import "LCCKUser.h"
#import "MWPhotoBrowser.h"
#import <objc/runtime.h>
#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif
//==================================================================================================================================
//If you want to see the storage of this demo, log in public account of leancloud.cn, search for the app named `LeanCloudChatKit-iOS`.
//======================================== username : leancloud@163.com , password : Public123 =====================================
//==================================================================================================================================

#warning TODO: CHANGE TO YOUR AppId and AppKey

static NSString *const LCCKAPPID = @"dYRQ8YfHRiILshUnfFJu2eQM-gzGzoHsz";
static NSString *const LCCKAPPKEY = @"ye24iIK6ys8IvaISMC4Bs5WK";
//static NSString *const LCCKAPPID = @"eBLWvezQIK0XbGoyhUAn614d-gzGzoHsz";
//static NSString *const LCCKAPPKEY = @"cjAQu6MAIVbxwihONRX3Ulx6";
// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@interface LCChatKitExample () <MWPhotoBrowserDelegate>

@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, strong) NSMutableArray *selections;

@end

@implementation LCChatKitExample

#pragma mark - SDK Life Control

+ (void)invokeThisMethodInDidFinishLaunching {
    //    [AVOSCloud setServiceRegion:AVServiceRegionUS];
    [AVOSCloud registerForRemoteNotification];
    [AVIMClient setTimeoutIntervalInSeconds:20];
    
}

+ (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)invokeThisMethodBeforeLogoutSuccess:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed {
    //    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
    [[LCChatKit sharedInstance] removeAllCachedProfiles];
    [[LCChatKit sharedInstance] closeWithCallback:^(BOOL succeeded, NSError *error) {
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
    [[self sharedInstance] exampleInit];
    
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
        //                alert = "lcckkit : sdfsdf";
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
    //        [LCChatKit setAllLogsEnabled:YES];
    [[LCChatKit sharedInstance] setUseDevPushCerticate:YES];
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
        
        NSMutableArray *users = [NSMutableArray arrayWithCapacity:userIds.count];
#warning 注意：以下方法循环模拟了通过 userIds 同步查询 user 信息的过程，这里需要替换为 App 的 API 同步查询
            [userIds enumerateObjectsUsingBlock:^(NSString * _Nonnull clientId, NSUInteger idx, BOOL * _Nonnull stop) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerId like %@", clientId ];
            NSArray *searchedUsers = [LCCKContactProfiles filteredArrayUsingPredicate:predicate];
            if (searchedUsers.count > 0) {
                NSDictionary *user = searchedUsers[0];
                NSURL *avatarURL = [NSURL URLWithString:user[LCCKProfileKeyAvatarURL]];
                LCCKUser *user_ = [LCCKUser userWithUserId:user[LCCKProfileKeyPeerId]
                                                      name:user[LCCKProfileKeyName]
                                                 avatarURL:avatarURL
                                                  clientId:clientId];
                [users addObject:user_];
            } else {
                //注意：如果网络请求失败，请至少提供 ClientId！
                LCCKUser *user_ = [LCCKUser userWithClientId:clientId];
                [users addObject:user_];
            }
        }];
        !callback ?: callback([users copy], nil);
    }];
    
    [[LCChatKit sharedInstance] setDidSelectConversationsListCellBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
        [[self class] exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId fromNavigationController:nil];
    }];
    
    [[LCChatKit sharedInstance] setDidDeleteConversationsListCellBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
        //TODO:
    }];
    
    [[LCChatKit sharedInstance] setPreviewImageMessageBlock:^(NSUInteger index, NSArray *allVisibleImages, NSArray *allVisibleThumbs, NSDictionary *userInfo) {
        [self examplePreviewImageMessageWithIndex:index allVisibleImages:allVisibleImages allVisibleThumbs:allVisibleThumbs];
    }];
    
    [[LCChatKit sharedInstance] setLongPressMessageBlock:^NSArray<UIMenuItem *> *(LCCKMessage *message, NSDictionary *userInfo) {
        LCCKMenuItem *copyItem = [[LCCKMenuItem alloc] initWithTitle:LCCKLocalizedStrings(@"copy")
                                                               block:^{
                                                                   UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                                   [pasteboard setString:[message text]];
                                                               }];
        NSArray *menuItems = [NSArray array];
        if (message.messageMediaType ==  LCCKMessageTypeText) {
            menuItems = @[ copyItem ];
        }
        return menuItems;
    }];
    
    [[LCChatKit sharedInstance] setHUDActionBlock:^(UIViewController *viewController, NSString *title, LCCKMessageHUDActionType type) {
        switch (type) {
            case LCCKMessageHUDActionTypeShow:
                [[self class] lcck_showMessage:title toView:viewController.view];
                break;
                
            case LCCKMessageHUDActionTypeHide:
                [[self class] lcck_hideHUDForView:viewController.view];
                break;
                
            case LCCKMessageHUDActionTypeError:
                [[self class] lcck_showError:title toView:viewController.view];
                break;
                
            case LCCKMessageHUDActionTypeSuccess:
                [[self class] lcck_showSuccess:title toView:viewController.view];
                break;
        }
    }];
    
    [[LCChatKit sharedInstance] setOpenProfileBlock:^(NSString *userId, id<LCCKUserDelegate> user, UIViewController *parentController) {
        [self exampleOpenProfileForUser:user userId:userId];
    }];
    
//    [[LCChatKit sharedInstance] setAvatarImageViewCornerRadiusBlock:^CGFloat(CGSize avatarImageViewSize) {
//        if (avatarImageViewSize.height > 0) {
//            return avatarImageViewSize.height/2;
//        }
//        return 5;
//    }];
    
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
        [[self class] lcck_showMessage:@"正在重新连接聊天服务..." toView:viewController.view];
        [[LCChatKit sharedInstance] openWithClientId:[LCChatKit sharedInstance].clientId callback:^(BOOL succeeded, NSError *error) {
            [[self class] lcck_hideHUDForView:viewController.view];
            if (succeeded) {
                [[self class] lcck_showSuccess:@"连接成功"];
                callback(succeeded, nil);
            } else {
                [[self class] lcck_showError:@"连接失败"];
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
    NSString *conversationId = conversation.conversationId;
    if (conversation.lcck_unreadCount > 0) {
        if (*title == nil) {
            *title = @"标记为已读";
        }
        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [controller.tableView setEditing:NO animated:YES];
            [[LCChatKit sharedInstance] updateUnreadCountToZeroWithConversationId:conversationId];
            [controller refresh];
        };
    } else {
        if (*title == nil) {
            *title = @"标记为未读";
        }
        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [controller.tableView setEditing:NO animated:YES];
            [[LCChatKit sharedInstance] increaseUnreadCountWithConversationId:conversationId];
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
                                                                                  [[LCChatKit sharedInstance] deleteRecentConversationWithConversationId:conversation.conversationId];
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
        [self lcck_showMessage:@"加载历史记录..." toView:viewController.view];
        [viewController configureBarButtonItemStyle:LCCKBarButtonItemStyleSingleProfile action:^{
            NSString *title = @"打开用户详情";
            NSString *subTitle = [NSString stringWithFormat:@"用户id：%@", peerId];
            [LCCKUtil showNotificationWithTitle:title subtitle:subTitle type:LCCKMessageNotificationTypeMessage];
        }];
    }];
    [conversationViewController setConversationHandler:^(AVIMConversation *conversation, LCCKConversationViewController *aConversationController) {
        if (!conversation) {
            [self lcck_hideHUDForView:aConversationController.view];
            [aConversationController.navigationController popViewControllerAnimated:YES];
            return;
        }
    }];
    [conversationViewController setLoadHistoryMessagesHandler:^(__kindof UIViewController *viewController, BOOL succeeded, NSError *error) {
        [self lcck_hideHUDForView:viewController.view];
        NSString *title;
        NSString *subtitle;
        LCCKMessageNotificationType type;
        if (succeeded) {
            title = @"聊天记录加载成功";
            type = LCCKMessageNotificationTypeSuccess;
        } else {
            title = @"聊天记录加载失败";
            type = LCCKMessageNotificationTypeError;
            subtitle = error.localizedDescription;
        }
        [LCCKUtil showNotificationWithTitle:title subtitle:subtitle type:type];
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
                NSArray *members = conversation.members;
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", @[ conversation.clientId ]];
                NSString *peerId = [members filteredArrayUsingPredicate:predicate][0];
                NSString *subTitle = [NSString stringWithFormat:@"用户id：%@", peerId];
                [LCCKUtil showNotificationWithTitle:title subtitle:subTitle type:LCCKMessageNotificationTypeMessage];
            }];
        }
    }];
    
    [conversationViewController setViewDidLoadBlock:^(LCCKBaseViewController *viewController) {
        [self lcck_showMessage:@"加载历史记录..." toView:viewController.view];
    }];
    [conversationViewController setLoadHistoryMessagesHandler:^(__kindof UIViewController *viewController, BOOL succeeded, NSError *error) {
        [self lcck_hideHUDForView:viewController.view];
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
        [self lcck_hideHUDForView:viewController.view];
    }];
    [self pushToViewController:conversationViewController];
}

+ (void)exampleCreateGroupConversationFromViewController:(UIViewController *)fromViewController {
    //FIXME: add more to allPersonIds
    NSArray *allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
    NSArray *users = [[LCChatKit sharedInstance] getProfilesForUserIds:allPersonIds error:nil];
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    LCCKContactListViewController *contactListViewController = [[LCCKContactListViewController alloc] initWithContacts:users userIds:allPersonIds excludedUserIds:@[currentClientID] mode:LCCKContactListModeMultipleSelection];
    contactListViewController.title = @"创建群聊";
    [contactListViewController setSelectedContactsCallback:^(UIViewController *viewController, NSArray<NSString *> *peerIds) {
        if (!peerIds || peerIds.count == 0) {
            return;
        }
        [self lcck_showText:@"创建群聊..." view:fromViewController.view];
        [[LCChatKit sharedInstance] createConversationWithMembers:peerIds type:LCCKConversationTypeGroup unique:YES callback:^(AVIMConversation *conversation, NSError *error) {
            [self lcck_hideHUDForView:fromViewController.view];
            [self lcck_showSuccess:@"创建成功" toView:fromViewController.view];
            [self exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId fromNavigationController:viewController.navigationController];
        }];
    }];
    UINavigationController *navigationViewController = [[UINavigationController alloc] initWithRootViewController:contactListViewController];
    [fromViewController presentViewController:navigationViewController animated:YES completion:nil];
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
        NSString *badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
        if (totalUnreadCount > 99) {
            badgeValue = @"...";
        }
        [controller tabBarItem].badgeValue = badgeValue;
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

- (void)examplePreviewImageMessageWithIndex:(NSUInteger)index allVisibleImages:(NSArray *)allVisibleImages allVisibleThumbs:(NSArray *)allVisibleThumbs {
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] initWithCapacity:[allVisibleImages count]];
    NSMutableArray *thumbs = [[NSMutableArray alloc] initWithCapacity:[allVisibleThumbs count]];
    MWPhoto *photo;
    MWPhoto *thumb;
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = YES;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    for (NSUInteger index = 0; index < allVisibleImages.count; index++) {
        id image_ = allVisibleImages[index];
        if ([image_ isKindOfClass:[UIImage class]]) {
            photo = [MWPhoto photoWithImage:image_];
        } else {
            photo = [MWPhoto photoWithURL:image_];
        }
        [photos addObject:photo];
        
        id thumb_ = allVisibleThumbs[index];
        if ([thumb_ isKindOfClass:[UIImage class]]) {
            thumb = [MWPhoto photoWithImage:thumb_];
        } else {
            thumb = [MWPhoto photoWithURL:thumb_];
        }
        [thumbs addObject:thumb];
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
        _selections = [[NSMutableArray alloc] initWithCapacity:[allVisibleImages count]];
        for (int i = 0; i < photos.count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    [[self class] pushToViewController:browser];
}

- (void)exampleOpenProfileForUser:(id<LCCKUserDelegate>)user userId:(NSString *)userId {
    NSString *title = [NSString stringWithFormat:@"打开用户主页 \nClientId是 : %@", userId];
    NSString *subtitle = [NSString stringWithFormat:@"name是 : %@", user.name];
    [LCCKUtil showNotificationWithTitle:title subtitle:subtitle type:LCCKMessageNotificationTypeMessage];
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
