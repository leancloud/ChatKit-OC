//
//  AVOSCloudIM.m
//  AVOS
//
//  Created by Tang Tianyong on 1/6/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <AVOSCloud/AVOSCloud.h>

#import "AVOSCloudIM.h"

@implementation AVOSCloudIM

+ (void)registerForRemoteNotification {
    [AVOSCloud registerForRemoteNotification];
}

+ (void)registerForRemoteNotificationTypes:(NSUInteger)types categories:(NSSet *)categories {
    [AVOSCloud registerForRemoteNotificationTypes:types categories:categories];
}

+ (void)handleRemoteNotificationsWithDeviceToken:(NSData *)deviceToken constructingInstallationWithBlock:(void (^)(AVInstallation *))block {
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken constructingInstallationWithBlock:block];
}

+ (void)handleRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken];
}

@end
