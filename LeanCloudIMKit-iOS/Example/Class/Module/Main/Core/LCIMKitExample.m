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
#import "MWPhotoBrowser.h"

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

+ (void)destroyInstance {
    [_sharedInstances removeObjectForKey:NSStringFromClass(self)];
}

#pragma mark - SDK Life Control

+ (void)invokeThisMethodInDidFinishLaunching {
    [AVOSCloudIM registerForRemoteNotification];
    [AVIMClient setTimeoutIntervalInSeconds:20];
    [[self sharedInstance] exampleInit];
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
            NSString *subtitle = [NSString stringWithFormat:@"User Id 是 : %@", clientId];
            [LCIMUtil showNotificationWithTitle:@"登陆成功" subtitle:subtitle type:LCIMMessageNotificationTypeSuccess];
            !success ?: success();
        } else {
            [LCIMUtil showNotificationWithTitle:@"登陆失败" subtitle:nil type:LCIMMessageNotificationTypeSuccess];
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
- (void)exampleInit {
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
        [[self class] exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId fromNavigationController:nil];
    }];
    
    [[LCIMKit sharedInstance] setPreviewImageMessageBlock:^(NSUInteger index, NSArray *imageMessageInfo, NSDictionary *userInfo) {
        [self examplePreviewImageMessageWithIndex:index imageMessages:imageMessageInfo];
    }];
    
    [[LCIMKit sharedInstance] setDidDeleteItemBlock:^(AVIMConversation *conversation) {
        //TODO:
    }];
    
    [[LCIMKit sharedInstance] setOpenProfileBlock:^(NSString *userId, UIViewController *parentController) {
        [self exampleOpenProfileForUserId:userId];
    }];
    
    [[LCIMKit sharedInstance] setShowNotificationBlock:^(UIViewController *viewController, NSString *title, NSString *subtitle, LCIMMessageNotificationType type) {
        [self exampleShowNotificationWithTitle:title subtitle:subtitle type:type];
    }];
    
    // 自定义Cell菜单
//    [[LCIMKit sharedInstance] setConversationEditActionBlock:^NSArray *(NSIndexPath *indexPath, NSArray *editActions) {
//        return [self exampleConversationEditAction:indexPath];
//    }];
}

- (NSArray *)exampleConversationEditAction:(NSIndexPath *)indexPath {
    // 如果需要自定义其他会话的菜单，在此编辑
    return [self rightButtons];
}

- (NSArray *)rightButtons {
    UITableViewRowAction *actionItemMore = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                              title:@"More"
                                                                            handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                                NSLog(@"More");
                                                                            }];
    actionItemMore.backgroundColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0];
    
    UITableViewRowAction *actionItemDelete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                                title:@"Delete"
                                                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                                                  //        [[LCIMConversationService sharedInstance] deleteConversation:conversation];
                                                                              }];
    return @[ actionItemDelete, actionItemMore ];
}

#pragma -
#pragma mark - Other Method

/**
 *  打开单聊页面
 */
+ (void)exampleOpenConversationViewControllerWithPeerId:(NSString *)peerId fromNavigationController:(UINavigationController *)navigationController {
    LCIMChatController *conversationViewController = [[LCIMChatController alloc] initWithPeerId:peerId];
    [self pushToViewController:conversationViewController];
}

+ (void)exampleOpenConversationViewControllerWithConversaionId:(NSString *)conversationId fromNavigationController:(UINavigationController *)aNavigationController {
    //    LCIMChatController *conversationViewController =[[LCIMChatController alloc] initWithConversationId:conversationId];
    
    LCIMChatController *conversationViewController =[[LCIMChatController alloc] initWithConversationId:@"56d880b9f3609a005d88415e"];
    
    [self pushToViewController:conversationViewController];
}

+ (void)pushToViewController:(UIViewController *)viewController {
    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
    UIWindow *window = delegate.window;
    UITabBarController *tabBarController = (UITabBarController *)window.rootViewController;
    UINavigationController *navigationController = tabBarController.selectedViewController;
    [navigationController pushViewController:viewController animated:YES];
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

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
//    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    //    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
