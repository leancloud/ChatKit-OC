//
//  LCIMKitExample.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/2/24.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMKitExample.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

@implementation LCIMKitExample

#pragma mark - SDK Life Control

- (void)invokeThisMethodInDidFinishLaunching {
    [AVOSCloudIM registerForRemoteNotification];
}

- (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)invokeThisMethodBeforeLogout {
    [AVOSCloudIM handleRemoteNotificationsWithDeviceToken:nil];
}

- (void)invokeThisMethodAfterLoginSuccess {
    //TODO:
}

@end
