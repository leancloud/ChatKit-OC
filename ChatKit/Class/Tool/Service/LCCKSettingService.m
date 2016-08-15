//
//  LCCKSettingService.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSettingService.h"
#import "AVOSCloudIM/AVIMVideoMessage.h"

NSString *const LCCKSettingServiceErrorDomain = @"LCCKSettingServiceErrorDomain";

static BOOL LCCKAllLogsEnabled;

@implementation LCCKSettingService
@synthesize useDevPushCerticate = _useDevPushCerticate;

+ (void)setAllLogsEnabled:(BOOL)enabled {
    LCCKAllLogsEnabled = enabled;
    [AVOSCloud setAllLogsEnabled:YES];
}

+ (BOOL)allLogsEnabled {
    return LCCKAllLogsEnabled;
}

+ (NSString *)ChatKitVersion {
    return @"1.0.0";
}

- (NSString *)tmpPath {
    return [[self getFilesPath] stringByAppendingFormat:@"%@", [[NSUUID UUID] UUIDString]];
}

- (NSString *)getFilesPath {
    NSString *appPath = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filesPath = [appPath stringByAppendingString:@"/files/"];
    NSFileManager *fileMan = [NSFileManager defaultManager];
    NSError *error;
    BOOL isDir = YES;
    if ([fileMan fileExistsAtPath:filesPath isDirectory:&isDir] == NO) {
        [fileMan createDirectoryAtPath:filesPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            [NSException raise:@"error when create dir" format:@"error"];
        }
    }
    return filesPath;
}

- (NSString *)getPathByObjectId:(NSString *)objectId {
    return [[self getFilesPath] stringByAppendingFormat:@"%@", objectId];
}

- (NSString *)videoPathOfMessage:(AVIMVideoMessage *)message {
    // 视频播放会根据文件扩展名来识别格式
    return [[self getFilesPath] stringByAppendingFormat:@"%@.%@", message.messageId, message.format];
}

- (void)registerForRemoteNotification {
    [AVOSCloud registerForRemoteNotification];
}

- (void)saveInstallationWithDeviceToken:(NSData *)deviceToken userId:(NSString *)userId {
    AVInstallation *currentInstallation = [AVInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    // openClient 的时候也会将 clientId 注册到 channels，这里多余了？
    if (userId) {
        [currentInstallation addUniqueObject:userId forKey:LCCKInstallationKeyChannels];
    }
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"%@", error);
    }];
}

- (void)pushMessage:(NSString *)message userIds:(NSArray *)userIds block:(AVBooleanResultBlock)block {
    AVPush *push = [[AVPush alloc] init];
    [push setChannels:userIds];
    [push setMessage:message];
    [push sendPushInBackgroundWithBlock:block];
}

- (void)cleanBadge {
    UIApplication *application = [UIApplication sharedApplication];
    NSInteger num = application.applicationIconBadgeNumber;
    if (num != 0) {
        AVInstallation *currentInstallation = [AVInstallation currentInstallation];
        [currentInstallation setBadge:0];
        [currentInstallation saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
            NSLog(@"%@", error ? error : @"succeed");
        }];
        application.applicationIconBadgeNumber = 0;
    }
    [application cancelAllLocalNotifications];
}

- (void)syncBadge {
    AVInstallation *currentInstallation = [AVInstallation currentInstallation];
    if (currentInstallation.badge != [UIApplication sharedApplication].applicationIconBadgeNumber) {
        [currentInstallation setBadge:[UIApplication sharedApplication].applicationIconBadgeNumber];
        [currentInstallation saveEventually: ^(BOOL succeeded, NSError *error) {
            NSLog(@"%@", error ? error : @"succeed");
        }];
    } else {
        //        NSLog(@"badge not changed");
    }
}

- (void)setUseDevPushCerticate:(BOOL)useDevPushCerticate {
    _useDevPushCerticate = useDevPushCerticate;
    [AVPush setProductionMode:!_useDevPushCerticate];
}

@end
