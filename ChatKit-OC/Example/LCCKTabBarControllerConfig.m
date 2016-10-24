//
//  LCChatKitExample.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKTabBarControllerConfig.h"
#import <AVOSCloud/AVOSCloud.h>
#import "LCChatKitExample.h"
#import "LCCKContactManager.h"
#import "NSObject+LCCKHUD.h"
#import "FTPopOverMenu.h"
#import "LCCKExampleConstants.h"

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@interface LCCKTabBarControllerConfig ()

@property (nonatomic, readwrite, strong) CYLTabBarController *tabBarController;
@property (nonatomic, strong) LCCKConversationListViewController *firstViewController;
@property (nonatomic, strong) LCCKContactListViewController *secondViewController;

@end

@implementation LCCKTabBarControllerConfig

/**
 *  lazy load tabBarController
 *
 *  @return CYLTabBarController
 */
- (CYLTabBarController *)tabBarController {
    if (_tabBarController == nil) {
        CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithViewControllers:self.viewControllers
                                                                                   tabBarItemsAttributes:self.tabBarItemsAttributesForController];
        [self customizeTabBarAppearance:tabBarController];
        _tabBarController = tabBarController;
    }
    return _tabBarController;
}

- (NSArray *)allPersonIds {
    NSArray *allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
    return allPersonIds;
}

- (NSArray *)viewControllers {
    LCCKConversationListViewController *firstViewController = [[LCCKConversationListViewController alloc] init];
    UINavigationController *firstNavigationController = [[LCCKBaseNavigationController alloc]
                                                         initWithRootViewController:firstViewController];
    [firstViewController configureBarButtonItemStyle:LCCKBarButtonItemStyleAdd action:^(UIBarButtonItem *sender, UIEvent *event) {
        [self showPopOverMenu:sender event:event];
    }];
    self.firstViewController = firstViewController;
    NSArray *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:self.allPersonIds shouldSameCount:YES error:nil];
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    LCCKContactListViewController *secondViewController = [[LCCKContactListViewController alloc] initWithContacts:[NSSet setWithArray:users] userIds:[NSSet setWithArray:self.allPersonIds] excludedUserIds:[NSSet setWithArray:@[currentClientID]] mode:LCCKContactListModeNormal];
    [secondViewController setSelectedContactCallback:^(UIViewController *viewController, NSString *peerId) {
        [LCChatKitExample exampleOpenConversationViewControllerWithPeerId:peerId fromNavigationController:self.tabBarController.navigationController];
    }];
    [secondViewController setDeleteContactCallback:^BOOL(UIViewController *viewController, NSString *peerId) {
        [[LCCKContactManager defaultManager] removeContactForPeerId:peerId];
        return YES;
    }];
    self.secondViewController = secondViewController;
    UINavigationController *secondNavigationController = [[LCCKBaseNavigationController alloc]
                                                          initWithRootViewController:secondViewController];
    secondViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出"
                                                                                              style:UIBarButtonItemStylePlain
                                                                                             target:self
                                                                                             action:@selector(signOut)];
    secondViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加好友"
                                                                                             style:UIBarButtonItemStylePlain
                                                                                            target:self
                                                                                            action:@selector(addFriend)];
    NSArray *viewControllers = @[
                                 firstNavigationController,
                                 secondNavigationController,
                                 ];
    return viewControllers;
}

- (NSArray *)tabBarItemsAttributesForController {
    NSDictionary *dict1 = @{
                            // CYLTabBarItemTitle : @"消息",
                            CYLTabBarItemImage : @"tabbar_chat_normal",
                            CYLTabBarItemSelectedImage : @"tabbar_chat_active",
                            };
    NSDictionary *dict2 = @{
                            // CYLTabBarItemTitle : @"联系人",
                            CYLTabBarItemImage : @"tabbar_contacts_normal",
                            CYLTabBarItemSelectedImage : @"tabbar_contacts_active",
                            };
    
    NSArray *tabBarItemsAttributes = @[
                                       dict1,
                                       dict2,
                                       ];
    return tabBarItemsAttributes;
}

/**
 *  更多TabBar自定义设置：比如：tabBarItem 的选中和不选中文字和背景图片属性、tabbar 背景图片属性等等
 */
- (void)customizeTabBarAppearance:(CYLTabBarController *)tabBarController {
    // Customize UITabBar height
    // 自定义 TabBar 高度
    tabBarController.tabBarHeight = 40.f;
    
    // set the text color for unselected state
    // 普通状态下的文字属性
    NSMutableDictionary *normalAttrs = [NSMutableDictionary dictionary];
    normalAttrs[NSForegroundColorAttributeName] = [UIColor grayColor];
    
    // set the text color for selected state
    // 选中状态下的文字属性
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = [UIColor blackColor];
    
    // set the text Attributes
    // 设置文字属性
    UITabBarItem *tabBar = [UITabBarItem appearance];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
    [tabBar setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    
    // Set the dark color to selected tab (the dimmed background)
    // TabBarItem选中后的背景颜色
    // [self customizeTabBarSelectionIndicatorImage];
    
    // update TabBar when TabBarItem width did update
    // If your app need support UIDeviceOrientationLandscapeLeft or UIDeviceOrientationLandscapeRight，
    // remove the comment '//'
    // 如果你的App需要支持横竖屏，请使用该方法移除注释 '//'
    // [self updateTabBarCustomizationWhenTabBarItemWidthDidUpdate];
    
    // set the bar shadow image
    // This shadow image attribute is ignored if the tab bar does not also have a custom background image.So at least set somthing.
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setBackgroundColor:[UIColor whiteColor]];
    [[UITabBar appearance] setShadowImage:[UIImage imageNamed:@"tapbar_top_line"]];
    
    // set the bar background image
    // 设置背景图片
    // UITabBar *tabBarAppearance = [UITabBar appearance];
    // [tabBarAppearance setBackgroundImage:[UIImage imageNamed:@"tabbar_background"]];
    
    // remove the bar system shadow image
    // 去除 TabBar 自带的顶部阴影
    // [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
}

- (void)updateTabBarCustomizationWhenTabBarItemWidthDidUpdate {
    void (^deviceOrientationDidChangeBlock)(NSNotification *) = ^(NSNotification *notification) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight)) {
            NSLog(@"Landscape Left or Right !");
        } else if (orientation == UIDeviceOrientationPortrait) {
            NSLog(@"Landscape portrait!");
        }
        [self customizeTabBarSelectionIndicatorImage];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemWidthDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:deviceOrientationDidChangeBlock];
}

- (void)customizeTabBarSelectionIndicatorImage {
    ///Get initialized TabBar Height if exists, otherwise get Default TabBar Height.
    UITabBarController *tabBarController = [self cyl_tabBarController] ?: [[UITabBarController alloc] init];
    CGFloat tabBarHeight = tabBarController.tabBar.frame.size.height;
    CGSize selectionIndicatorImageSize = CGSizeMake(CYLTabBarItemWidth, tabBarHeight);
    //Get initialized TabBar if exists.
    UITabBar *tabBar = [self cyl_tabBarController].tabBar ?: [UITabBar appearance];
    [tabBar setSelectionIndicatorImage:
     [[self class] imageWithColor:[UIColor redColor]
                             size:selectionIndicatorImageSize]];
}

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width + 1, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createGroupConversation:(id)sender {
    [LCChatKitExample exampleCreateGroupConversationFromViewController:self.firstViewController];
}

- (NSString *)arc4randomString {
    int a = arc4random_uniform(100000000);
    NSString *arc4randomString = [NSString stringWithFormat:@"%@", @(a)];
    return arc4randomString;
}

- (void)addFriend {
    NSString *additionUserId = self.arc4randomString;
    NSMutableSet *addedUserIds = [NSMutableSet setWithSet:self.secondViewController.userIds];
    [addedUserIds addObject:additionUserId];
    self.secondViewController.userIds = [addedUserIds copy];
}

- (void)showPopOverMenu:(UIBarButtonItem *)sender event:(UIEvent *)event {
    [FTPopOverMenu showFromEvent:event
                        withMenu:@[ @"创建群聊" ]
                       doneBlock:^(NSInteger selectedIndex) {
                           if (selectedIndex == 0) {
                               [self createGroupConversation:sender];
                           }
                       } dismissBlock:nil];
}

- (void)signOut {
    [LCChatKitExample signOutFromViewController:self.secondViewController];
}

- (void)changeGroupAvatar {
    [LCChatKitExample exampleChangeGroupAvatarURLsForConversationId:@"570da6a9daeb3a63ca5b07b0"];
}

@end
