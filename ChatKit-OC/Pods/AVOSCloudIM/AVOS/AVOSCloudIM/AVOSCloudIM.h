//
//  AVOSCloudIM.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//


// In this header, you should import all the public headers of your framework using statements like #import <AVOSCloudIM/PublicHeader.h>

// Public headers
#import "AVIMAvailability.h"
#import "AVIMCommon.h"
#import "AVIMClient.h"
#import "AVIMClientOpenOption.h"
#import "AVIMConversation.h"
#import "AVIMKeyedConversation.h"
#import "AVIMConversationQuery.h"
#import "AVIMConversationUpdateBuilder.h"
#import "AVIMMessage.h"
#import "AVIMMessageOption.h"
#import "AVIMTypedMessage.h"
#import "AVIMTextMessage.h"
#import "AVIMImageMessage.h"
#import "AVIMAudioMessage.h"
#import "AVIMVideoMessage.h"
#import "AVIMLocationMessage.h"
#import "AVIMFileMessage.h"
#import "AVIMSignature.h"
#import "AVIMUserOptions.h"

@class AVInstallation;

@interface AVOSCloudIM : NSObject

/**
 * Register remote notification with all types (badge, alert, sound) and empty categories.
 */
+ (void)registerForRemoteNotification AVIM_TV_UNAVAILABLE AVIM_WATCH_UNAVAILABLE \
    AVIM_DEPRECATED("Deprecated in AVOSCloud SDK 3.2.8. It will be removed in future.");

/**
 * Register remote notification with types.
 * @param types Notification types.
 * @param categories A set of UIUserNotificationCategory objects that define the groups of actions a notification may include.
 * NOTE: categories only supported by iOS 8 and later. If application run below iOS 8, categories will be ignored.
 */
+ (void)registerForRemoteNotificationTypes:(NSUInteger)types categories:(NSSet *)categories AVIM_TV_UNAVAILABLE AVIM_WATCH_UNAVAILABLE \
    AVIM_DEPRECATED("Deprecated in AVOSCloud SDK 3.2.8. It will be removed in future.");

/**
 * Handle device token registered from APNs.
 * @param deviceToken Device token issued by APNs.
 * This method should be called in -[UIApplication application:didRegisterForRemoteNotificationsWithDeviceToken:].
 */
+ (void)handleRemoteNotificationsWithDeviceToken:(NSData *)deviceToken \
    AVIM_DEPRECATED("Deprecated in AVOSCloud SDK 3.2.8. Use +[AVOSCloud handleRemoteNotificationsWithDeviceToken:] instead.");

/**
 * Handle device token registered from APNs.
 * @param deviceToken Device token issued by APNs.
 * @param block       Constructing block of [AVInstallation currentInstallation].
 * This method should be called in -[UIApplication application:didRegisterForRemoteNotificationsWithDeviceToken:].
 */
+ (void)handleRemoteNotificationsWithDeviceToken:(NSData *)deviceToken constructingInstallationWithBlock:(void (^)(AVInstallation *currentInstallation))block \
    AVIM_DEPRECATED("Deprecated in AVOSCloud SDK 3.2.8. Use +[AVOSCloud handleRemoteNotificationsWithDeviceToken:constructingInstallationWithBlock:] instead.");

@end
