//
//  LCIMKit.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMKit.h"

// Dictionary that holds all instances of Singleton include subclasses
static NSMutableDictionary *_sharedInstances = nil;

@interface LCIMKit ()

@property (nonatomic, copy, readwrite) LCIMOpenProfileBlock openProfileBlock;

/*!
 * open or close client Service
 */
@property (nonatomic, strong, readwrite) LCIMSessionService *sessionService;

/*!
 * User-System Service
 */
@property (nonatomic, strong, readwrite) LCIMUserSystemService *userSystemService;

/*!
 * Signature Service
 */
@property (nonatomic, strong, readwrite) LCIMSignatureService *signatureService;

/*!
 * Setting Service
 */
@property (nonatomic, strong, readwrite) LCIMSettingService *settingService;

/*!
 * UI Service
 */
@property (nonatomic, strong, readwrite) LCIMUIService *UIService;

/*!
 * Conversation Service
 */
@property (nonatomic, strong, readwrite) LCIMConversationService *conversationService;

@end

@implementation LCIMKit

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

#pragma mark -
#pragma mark - LCIMKit Method

+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey {
    [AVOSCloud setApplicationId:appId clientKey:appKey];
    if ([LCIMSettingService allLogsEnabled]) {
        NSLog(@"LeanCloudKit Version is %@", [LCIMSettingService IMKitVersion]);
    }
}

#pragma mark -
#pragma mark - Service Delegate Method

- (LCIMSessionService *)sessionService {
    return [LCIMSessionService sharedInstance];
}

- (LCIMUserSystemService *)userSystemService {
    return [LCIMUserSystemService sharedInstance];
}

- (LCIMSignatureService *)signatureService {
    return [LCIMSignatureService sharedInstance];
}

- (LCIMSettingService *)settingService {
    return [LCIMSettingService sharedInstance];
}

- (LCIMUIService *)UIService {
    return [LCIMUIService sharedInstance];
}

- (LCIMConversationService *)conversationService {
    return [LCIMConversationService sharedInstance];
}

- (LCIMConversationListService *)conversationListService {
    return [LCIMConversationListService sharedInstance];
}

///---------------------------------------------------------------------
///---------------------LCIMSessionService------------------------------
///---------------------------------------------------------------------

- (NSString *)clientId {
    return [[LCIMKit sharedInstance] sessionService].clientId;
}

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback {
    [[[LCIMKit sharedInstance] sessionService] openWithClientId:clientId callback:callback];
}

- (void)closeWithCallback:(LCIMBooleanResultBlock)callback {
    [[[LCIMKit sharedInstance] sessionService] closeWithCallback:callback];
}

///--------------------------------------------------------------------
///----------------------LCIMUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUserSystemService

- (void)setFetchProfilesBlock:(LCIMFetchProfilesBlock)fetchProfilesBlock {
    [[[LCIMKit sharedInstance] userSystemService] setFetchProfilesBlock:fetchProfilesBlock];
}

- (void)removeAllCachedProfiles {
    [[[LCIMKit sharedInstance] userSystemService] removeAllCachedProfiles];
}

///--------------------------------------------------------------------
///----------------------LCIMSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSignatureService

- (void)setGenerateSignatureBlock:(LCIMGenerateSignatureBlock)generateSignatureBlock {
    [[[LCIMKit sharedInstance] signatureService] setGenerateSignatureBlock:generateSignatureBlock];
}

- (LCIMGenerateSignatureBlock)generateSignatureBlock {
    return [[[LCIMKit sharedInstance] signatureService] generateSignatureBlock];
}

///--------------------------------------------------------------------
///----------------------------LCIMUIService---------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUIService

#pragma mark - - Open Profile

- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock {
    [[[LCIMKit sharedInstance] UIService] setOpenProfileBlock:openProfileBlock];
}

- (void)setPreviewImageMessageBlock:(LCIMPreviewImageMessageBlock)previewImageMessageBlock {
    [[[LCIMKit sharedInstance] UIService] setPreviewImageMessageBlock:previewImageMessageBlock];
}

- (void)setPreviewLocationMessageBlock:(LCIMPreviewLocationMessageBlock)previewLocationMessageBlock {
    [[[LCIMKit sharedInstance] UIService] setPreviewLocationMessageBlock:previewLocationMessageBlock];
}


- (void)setShowNotificationBlock:(LCIMShowNotificationBlock)showNotificationBlock {
    [[[LCIMKit sharedInstance] UIService] setShowNotificationBlock:showNotificationBlock];
}

///---------------------------------------------------------------------
///------------------LCIMSettingService---------------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSettingService

+ (void)setAllLogsEnabled:(BOOL)enabled {
    [LCIMSettingService setAllLogsEnabled:YES];
}

+ (BOOL)allLogsEnabled {
   return [LCIMSettingService allLogsEnabled];
}

+ (NSString *)IMKitVersion {
    return [LCIMSettingService IMKitVersion];
}

- (void)syncBadge {
    [[LCIMSettingService sharedInstance] syncBadge];
}

- (BOOL)useDevPushCerticate {
    return [[LCIMSettingService sharedInstance] useDevPushCerticate];
}

- (void)setUseDevPushCerticate:(BOOL)useDevPushCerticate {
    [LCIMSettingService sharedInstance].useDevPushCerticate = useDevPushCerticate;
}

///---------------------------------------------------------------------
///---------------------LCIMConversationService-------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMConversationService

- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(AVIMConversationResultBlock)callback {
    [[[LCIMKit sharedInstance] conversationService] fecthConversationWithConversationId:conversationId callback:callback];
}

- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback {
    [[[LCIMKit sharedInstance] conversationService] fecthConversationWithPeerId:peerId callback:callback];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[LCIMKit sharedInstance] didReceiveRemoteNotification:userInfo];
}

///---------------------------------------------------------------------
///---------------------LCIMConversationsListService--------------------
///---------------------------------------------------------------------

- (void)setDidSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)didSelectItemBlock {
    [[[LCIMKit sharedInstance] conversationListService] setDidSelectItemBlock:didSelectItemBlock];
}

- (void)setDidDeleteItemBlock:(LCIMConversationsListDidDeleteItemBlock)didDeleteItemBlock {
    [[[LCIMKit sharedInstance] conversationListService] setDidDeleteItemBlock:didDeleteItemBlock];
}

- (void)setConversationEditActionBlock:(LCIMConversationEditActionsBlock)conversationEditActionBlock {
    [[[LCIMKit sharedInstance] conversationListService] setConversationEditActionBlock:conversationEditActionBlock];
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCIMMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    [[[LCIMKit sharedInstance] conversationListService] setMarkBadgeWithTotalUnreadCountBlock:markBadgeWithTotalUnreadCountBlock];
}

//TODO:CacheService;

@end


