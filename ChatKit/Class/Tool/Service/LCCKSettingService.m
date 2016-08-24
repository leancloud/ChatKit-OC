//
//  LCCKSettingService.m
//  LeanCloudChatKit-iOS
//
//  v0.6.2 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSettingService.h"
#import "AVOSCloudIM/AVIMVideoMessage.h"
#import "NSBundle+LCCKExtension.h"
#import "NSString+LCCKExtension.h"
#import "UIImage+LCCKExtension.h"
#import "LCCKConversationService.h"

NSString *const LCCKSettingServiceErrorDomain = @"LCCKSettingServiceErrorDomain";

static BOOL LCCKAllLogsEnabled;

@interface LCCKSettingService ()

@property (nonatomic, strong) NSDictionary *defaultSettings;
@property (nonatomic, strong) NSDictionary *defaultTheme;

@end

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

- (NSDictionary *)defaultSettings {
    if (_defaultSettings) {
        return _defaultSettings;
    }
    NSBundle *bundle = [NSBundle lcck_bundleForName:@"Other" class:[self class]];
    NSString *defaultSettingsFile = [bundle pathForResource:@"ChatKit-Settings" ofType:@"plist"];
    NSDictionary *defaultSettings = [[NSDictionary alloc] initWithContentsOfFile:defaultSettingsFile];
    _defaultSettings = defaultSettings;
    return _defaultSettings;
}

- (NSDictionary *)defaultTheme {
    if (_defaultTheme) {
        return _defaultTheme;
    }
    NSBundle *bundle = [NSBundle lcck_bundleForName:@"Other" class:[self class]];
    NSString *defaultThemeFile = [bundle pathForResource:@"ChatKit-Theme" ofType:@"plist"];
    NSDictionary *defaultTheme = [[NSDictionary alloc] initWithContentsOfFile:defaultThemeFile];
    _defaultTheme = defaultTheme;
    return _defaultTheme;
}

- (UIColor *)defaultThemeColorForKey:(NSString *)key {
    UIColor *defaultThemeColor = [self.defaultTheme[@"Colors"][key] lcck_hexStringToColor];
    return defaultThemeColor;
}

- (void)setConversationViewControllerBackgroundImage:(UIImage *)image scaledToSize:(CGSize)scaledToSize {
    image = [image lcck_scalingPatternImageToSize:scaledToSize];
    NSData *imageData = (UIImagePNGRepresentation(image) ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, 1));
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
    NSString *imagePath = [imageName lcck_pathForConversationBackgroundImage];;
    [[NSFileManager defaultManager] createFileAtPath:imagePath contents:imageData attributes:nil];
    NSString *conversationId = [LCCKConversationService sharedInstance].currentConversation.conversationId;
    if (conversationId.length > 0) {
        NSString *customImageNameKey = [NSString stringWithFormat:@"%@%@_%@", LCCKCustomConversationViewControllerBackgroundImageNamePrefix, [LCCKSessionService sharedInstance].clientId, conversationId];
        [[NSUserDefaults standardUserDefaults] setObject:imageName forKey:customImageNameKey];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:imageName forKey:LCCKDefaultConversationViewControllerBackgroundImageName];
    }
    NSDictionary *userInfo = @{
                               LCCKNotificationConversationViewControllerBackgroundImageDidChangedUserInfoConversationIdKey : conversationId,
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationViewControllerBackgroundImageDidChanged object:userInfo];
}

@end
