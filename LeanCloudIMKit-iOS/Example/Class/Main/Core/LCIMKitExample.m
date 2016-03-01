//
//  LCIMKitExample.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMKitExample.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMUtil.h"
#import "LCIMConversationViewController.h"

//==================================================================================================================================
//If you want to see the storage of this demo, log in public account of leancloud.cn, search for the app named `LeanCloudIMKit-iOS`.
//======================================== username : leancloud@163.com , password : Public123 =====================================
//==================================================================================================================================

#warning TODO: CHANGE TO YOUR AppId and AppKey
static NSString *const LCIMAPPID = @"ykFkmeXIYRPiK2UfvGWXMWqV-gzGzoHsz";
static NSString *const LCIMAPPKEY = @"QgVhp43j6puGNQ0sAqNW64uH";

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
    [self exampleInit];
    [AVOSCloudIM registerForRemoteNotification];
}

+ (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)invokeThisMethodBeforeLogout {
    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
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

#pragma -
#pragma mark - LCIMSettingService Method

/**
 *  初始化的示例代码
 */
+ (void)exampleInit {
    [LCIMKit setAllLogsEnabled:YES];
    [LCIMKit setAppId:LCIMAPPID appKey:LCIMAPPKEY];
}

#pragma -
#pragma mark - Other  Method

/**
 *  打开单聊页面
 */
- (void)exampleOpenConversationViewControllerWithUserId:(NSString *)userId fromNavigationController:(UINavigationController *)aNavigationController {
//    AVIMConversation *conversation = [AVIMConversation fetchConversationByPerson:aPerson creatIfNotExist:YES];
    LCIMConversationViewController *conversaionViewController = [[LCIMConversationViewController alloc] init];

//    [self exampleOpenConversationViewControllerWithConversation:conversation fromNavigationController:aNavigationController];
}


@end
