//
//  LCCKSettingService.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/23.
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
@property (nonatomic, strong) NSDictionary *messageBubbleCustomizeSettings;

@end

@implementation LCCKSettingService
@synthesize useDevPushCerticate = _useDevPushCerticate;
@synthesize disablePreviewUserId = _disablePreviewUserId;

+ (void)setAllLogsEnabled:(BOOL)enabled {
    LCCKAllLogsEnabled = enabled;
    [AVOSCloud setAllLogsEnabled:YES];
}

+ (BOOL)allLogsEnabled {
    return LCCKAllLogsEnabled;
}

+ (NSString *)ChatKitVersion {
    NSString *v = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *version = [NSString stringWithFormat:@"v%@", v];
    return version;
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
    //FIXME: openClient 的时候也会将 clientId 注册到 channels，这里多余了？
    if (userId) {
        [currentInstallation addUniqueObject:userId forKey:LCCKInstallationKeyChannels];
    }
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"%@", error);
    }];
}

//TODO:Never used
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

- (NSDictionary *)messageBubbleCustomizeSettings {
    if (_messageBubbleCustomizeSettings) {
        return _messageBubbleCustomizeSettings;
    }
    NSBundle *bundle = [NSBundle lcck_bundleForName:@"MessageBubble" class:[self class]];
    NSString *messageBubbleCustomizeSettingsFile = [bundle pathForResource:@"MessageBubble-Customize" ofType:@"plist"];
    NSDictionary *messageBubbleCustomizeSettings =  [[NSDictionary alloc] initWithContentsOfFile:messageBubbleCustomizeSettingsFile];
    _messageBubbleCustomizeSettings = messageBubbleCustomizeSettings;
    return _messageBubbleCustomizeSettings;
}

/**
 * @param capOrEdge 分为：cap_insets和edge_insets
 * @param position 主要分为：CommonLeft、CommonRight等
 */
- (UIEdgeInsets)messageBubbleCustomizeSettingsForPosition:(NSString *)position capOrEdge:(NSString *)capOrEdge {
    NSDictionary *CapOrEdgeDict = self.messageBubbleCustomizeSettings[@"BubbleStyle"][position][@"background"][capOrEdge];
    CGFloat top = [(NSNumber *)CapOrEdgeDict[@"top"] floatValue];
    CGFloat left = [(NSNumber *)CapOrEdgeDict[@"left"] floatValue];
    CGFloat bottom = [(NSNumber *)CapOrEdgeDict[@"bottom"] floatValue];
    CGFloat right = [(NSNumber *)CapOrEdgeDict[@"right"] floatValue];
    UIEdgeInsets CapOrEdge = UIEdgeInsetsMake(top, left, bottom, right);
    return CapOrEdge;
}

- (UIEdgeInsets)rightCapMessageBubbleCustomize {
    UIEdgeInsets rightCapMessageBubbleCustomizeSettings = [self messageBubbleCustomizeSettingsForPosition:@"CommonRight" capOrEdge:@"cap_insets"];
    return rightCapMessageBubbleCustomizeSettings;
}

- (UIEdgeInsets)rightEdgeMessageBubbleCustomize {
    UIEdgeInsets rightEdgeMessageBubbleCustomizeSettings = [self messageBubbleCustomizeSettingsForPosition:@"CommonRight" capOrEdge:@"edge_insets"];
    return rightEdgeMessageBubbleCustomizeSettings;
}

- (UIEdgeInsets)leftCapMessageBubbleCustomize {
    UIEdgeInsets leftCapMessageBubbleCustomizeSettings = [self messageBubbleCustomizeSettingsForPosition:@"CommonLeft" capOrEdge:@"cap_insets"];
    return leftCapMessageBubbleCustomizeSettings;
}

- (UIEdgeInsets)leftEdgeMessageBubbleCustomize {
    UIEdgeInsets leftEdgeMessageBubbleCustomizeSettings = [self messageBubbleCustomizeSettingsForPosition:@"CommonLeft" capOrEdge:@"edge_insets"];
    return leftEdgeMessageBubbleCustomizeSettings;
}

- (UIEdgeInsets)rightHollowCapMessageBubbleCustomize {
    UIEdgeInsets rightHollowCapMessageBubbleCustomize = [self messageBubbleCustomizeSettingsForPosition:@"HollowRight" capOrEdge:@"cap_insets"];
    return rightHollowCapMessageBubbleCustomize;
}

- (UIEdgeInsets)rightHollowEdgeMessageBubbleCustomize {
    UIEdgeInsets rightHollowCapMessageBubbleCustomize = [self messageBubbleCustomizeSettingsForPosition:@"HollowRight" capOrEdge:@"edge_insets"];
    return rightHollowCapMessageBubbleCustomize;
}

- (UIEdgeInsets)leftHollowCapMessageBubbleCustomize {
    UIEdgeInsets leftHollowCapMessageBubbleCustomize = [self messageBubbleCustomizeSettingsForPosition:@"HollowLeft" capOrEdge:@"cap_insets"];
    return leftHollowCapMessageBubbleCustomize;
}

- (UIEdgeInsets)leftHollowEdgeMessageBubbleCustomize {
    UIEdgeInsets leftHollowEdgeMessageBubbleCustomize = [self messageBubbleCustomizeSettingsForPosition:@"HollowLeft" capOrEdge:@"edge_insets"];
    return leftHollowEdgeMessageBubbleCustomize;
}

- (NSString *)imageNameForMessageBubbleCustomizeForPosition:(NSString *)position normalOrHighlight:(NSString *)normalOrHighlight {
    NSString *imageNameForMessageBubbleCustomizeForPosition = self.messageBubbleCustomizeSettings[@"BubbleStyle"][position][@"background"][normalOrHighlight];
    return imageNameForMessageBubbleCustomizeForPosition;
}

- (NSString *)leftNormalImageNameMessageBubbleCustomize {
    NSString *leftNormalImageNameMessageBubbleCustomize = [self imageNameForMessageBubbleCustomizeForPosition:@"CommonLeft" normalOrHighlight:@"image_name_normal"];
    return leftNormalImageNameMessageBubbleCustomize;
}

- (NSString *)leftHighlightImageNameMessageBubbleCustomize {
    NSString *leftHighlightImageNameMessageBubbleCustomize = [self imageNameForMessageBubbleCustomizeForPosition:@"CommonLeft" normalOrHighlight:@"image_name_highlight"];
    return leftHighlightImageNameMessageBubbleCustomize;
}

- (NSString *)rightHighlightImageNameMessageBubbleCustomize {
    NSString *rightHighlightImageNameMessageBubbleCustomize = [self imageNameForMessageBubbleCustomizeForPosition:@"CommonRight" normalOrHighlight:@"image_name_highlight"];
    return rightHighlightImageNameMessageBubbleCustomize;
}

- (NSString *)rightNormalImageNameMessageBubbleCustomize {
    NSString *rightNormalImageNameMessageBubbleCustomize = [self imageNameForMessageBubbleCustomizeForPosition:@"CommonRight" normalOrHighlight:@"image_name_normal"];
    return rightNormalImageNameMessageBubbleCustomize;
}

- (NSString *)hollowRightNormalImageNameMessageBubbleCustomize {
    NSString *hollowRightNormalImageNameMessageBubbleCustomize = [self imageNameForMessageBubbleCustomizeForPosition:@"HollowRight" normalOrHighlight:@"image_name_normal"];
    return hollowRightNormalImageNameMessageBubbleCustomize;
}

- (NSString *)hollowRightHighlightImageNameMessageBubbleCustomize {
    NSString *hollowRightHighlightImageNameMessageBubbleCustomize = [self imageNameForMessageBubbleCustomizeForPosition:@"HollowRight" normalOrHighlight:@"image_name_highlight"];
    return hollowRightHighlightImageNameMessageBubbleCustomize;
}

- (NSString *)hollowLeftNormalImageNameMessageBubbleCustomize {
   NSString *hollowLeftNormalImageNameMessageBubbleCustomize =  [self imageNameForMessageBubbleCustomizeForPosition:@"HollowLeft" normalOrHighlight:@"image_name_normal"];
    return hollowLeftNormalImageNameMessageBubbleCustomize;
}

- (NSString *)hollowLeftHighlightImageNameMessageBubbleCustomize {
    NSString *hollowLeftHighlightImageNameMessageBubbleCustomize =  [self imageNameForMessageBubbleCustomizeForPosition:@"HollowLeft" normalOrHighlight:@"image_name_highlight"];
    return hollowLeftHighlightImageNameMessageBubbleCustomize;
}


- (UIColor *)defaultThemeColorForKey:(NSString *)key {
    UIColor *defaultThemeColor = [self.defaultTheme[@"Colors"][key] lcck_hexStringToColor];
    return defaultThemeColor;
}

- (UIFont *)defaultThemeTextMessageFont {
    CGFloat defaultThemeTextMessageFontSize = [self.defaultTheme[@"Fonts"][@"ConversationView-Message-TextSystemFontSize"] floatValue];
    UIFont *defaultThemeTextMessageFont = [UIFont systemFontOfSize:defaultThemeTextMessageFontSize];
    return defaultThemeTextMessageFont;
}

- (void)setBackgroundImage:(UIImage *)image forConversationId:(NSString *)conversationId scaledToSize:(CGSize)scaledToSize {
    if (conversationId.length == 0 || !conversationId) {
        return;
    }
    image = [image lcck_scalingPatternImageToSize:scaledToSize];
    NSData *imageData = (UIImagePNGRepresentation(image) ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, 1));
    NSString *imageName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID] UUIDString]];
    NSString *imagePath = [imageName lcck_pathForConversationBackgroundImage];;
    [[NSFileManager defaultManager] createFileAtPath:imagePath contents:imageData attributes:nil];
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
