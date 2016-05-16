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

@end

@implementation LCIMKit
@synthesize sessionNotOpenedHandler = _sessionNotOpenedHandler;
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
    return self.sessionService.clientId;
}

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback {
    [self.sessionService openWithClientId:clientId callback:callback];
}

- (void)closeWithCallback:(LCIMBooleanResultBlock)callback {
    [self.sessionService closeWithCallback:callback];
}
- (void)setSessionNotOpenedHandler:(LCCKSessionNotOpenedHandler)sessionNotOpenedHandler {
    [self.sessionService setSessionNotOpenedHandler:sessionNotOpenedHandler];
}

///--------------------------------------------------------------------
///----------------------LCIMUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUserSystemService

- (void)setFetchProfilesBlock:(LCIMFetchProfilesBlock)fetchProfilesBlock {
    [self.userSystemService setFetchProfilesBlock:fetchProfilesBlock];
}

- (void)removeAllCachedProfiles {
    [self.userSystemService removeAllCachedProfiles];
}

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatorURL:(NSURL **)avatorURL error:(NSError * __autoreleasing *)error {
    [self.userSystemService getCachedProfileIfExists:userId name:name avatorURL:avatorURL error:error];
}

- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCIMUserResultCallBack)callback {
    [self.userSystemService getProfileInBackgroundForUserId:userId callback:callback];
}

///--------------------------------------------------------------------
///----------------------LCIMSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSignatureService

- (void)setGenerateSignatureBlock:(LCIMGenerateSignatureBlock)generateSignatureBlock {
    [self.signatureService setGenerateSignatureBlock:generateSignatureBlock];
}

- (LCIMGenerateSignatureBlock)generateSignatureBlock {
    return [self.signatureService generateSignatureBlock];
}

///--------------------------------------------------------------------
///----------------------------LCIMUIService---------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUIService

#pragma mark - - Open Profile

- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock {
    [self.UIService setOpenProfileBlock:openProfileBlock];
}

- (void)setPreviewImageMessageBlock:(LCIMPreviewImageMessageBlock)previewImageMessageBlock {
    [self.UIService setPreviewImageMessageBlock:previewImageMessageBlock];
}

- (void)setPreviewLocationMessageBlock:(LCIMPreviewLocationMessageBlock)previewLocationMessageBlock {
    [self.UIService setPreviewLocationMessageBlock:previewLocationMessageBlock];
}

- (void)setShowNotificationBlock:(LCIMShowNotificationBlock)showNotificationBlock {
    [self.UIService setShowNotificationBlock:showNotificationBlock];
}

- (void)setAvatarImageViewCornerRadiusBlock:(LCIMAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock {
    [self.UIService setAvatarImageViewCornerRadiusBlock:avatarImageViewCornerRadiusBlock];
}

- (LCIMAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock {
    return self.UIService.avatarImageViewCornerRadiusBlock;
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
    [self.conversationService fecthConversationWithConversationId:conversationId callback:callback];
}

- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback {
    [self.conversationService fecthConversationWithPeerId:peerId callback:callback];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self.conversationService didReceiveRemoteNotification:userInfo];
}

- (void)increaseUnreadCountWithConversation:(AVIMConversation *)conversation {
    [self.conversationService increaseUnreadCountWithConversation:conversation];
}

- (void)deleteRecentConversation:(AVIMConversation *)conversation {
    [self.conversationService deleteRecentConversation:conversation];
}

- (void)updateUnreadCountToZeroWithConversation:(AVIMConversation *)conversation {
    [self.conversationService updateUnreadCountToZeroWithConversation:conversation];
}

- (void)removeAllCachedRecentConversations {
    [self.conversationService removeAllCachedRecentConversations];
}

///---------------------------------------------------------------------
///---------------------LCIMConversationsListService--------------------
///---------------------------------------------------------------------

- (void)setDidSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)didSelectItemBlock {
    [self.conversationListService setDidSelectItemBlock:didSelectItemBlock];
}

- (void)setDidDeleteItemBlock:(LCIMConversationsListDidDeleteItemBlock)didDeleteItemBlock {
    [self.conversationListService setDidDeleteItemBlock:didDeleteItemBlock];
}

- (void)setConversationEditActionBlock:(LCIMConversationEditActionsBlock)conversationEditActionBlock {
    [self.conversationListService setConversationEditActionBlock:conversationEditActionBlock];
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCIMMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    [self.conversationListService setMarkBadgeWithTotalUnreadCountBlock:markBadgeWithTotalUnreadCountBlock];
}

//TODO:CacheService;

@end


