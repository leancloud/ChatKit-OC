//
//  AVIMConversation+LCCKExtension.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "AVIMConversation+LCCKExtension.h"
#import <objc/runtime.h>
#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"
#import "LCCKUserDelegate.h"
#import "NSDate+LCCKDateTools.h"
#import "AVIMMessage+LCCKExtension.h"

@implementation AVIMConversation (LCCKExtension)

- (AVIMTypedMessage *)lcck_lastMessage {
    AVIMTypedMessage *visiableLastMessage = nil;
    AVIMTypedMessage *lastMessageFromCache = [self.lastMessage lcck_getValidTypedMessage];
    id visiableForPartClientIds = [lastMessageFromCache.attributes
                                   valueForKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
    BOOL isArray = [visiableForPartClientIds isKindOfClass:[NSArray class]];
    BOOL isString = [visiableForPartClientIds isKindOfClass:[NSString class]];
    if (!visiableForPartClientIds) {
        visiableLastMessage = lastMessageFromCache;
    } else if (isArray && ([(NSArray *)visiableForPartClientIds count] > 0)) {
        BOOL visiableForCurrentClientId =
        [visiableForPartClientIds containsObject:[LCChatKit sharedInstance].clientId];
        if (visiableForCurrentClientId) {
            visiableLastMessage = lastMessageFromCache;
        }
    } else if (isString && ([(NSString *)visiableForPartClientIds length] > 0)) {
        if ([visiableForPartClientIds isEqualToString:[LCChatKit sharedInstance].clientId]) {
            visiableLastMessage = lastMessageFromCache;
        }
    }
    return visiableLastMessage;
}

- (NSDate *)lcck_lastMessageAt {
    NSDate *dateFromServer = self.lastMessageAt;
    NSDate *dateFromCache = [NSDate dateWithTimeIntervalSince1970:self.lcck_lastMessage.sendTimestamp / 1000];
    BOOL isServerLate = [dateFromServer lcck_isLaterThan:dateFromCache];
    return isServerLate ? dateFromServer : dateFromCache;
}

- (NSInteger)lcck_unreadCount
{
    return self.unreadMessagesCount;
}

- (NSString *)lcck_badgeText {
    NSString *badgeText;
    NSUInteger unreadCount = self.lcck_unreadCount;
    if (unreadCount > 99) {
        badgeText = LCCKBadgeTextForNumberGreaterThanLimit;
    } else {
        badgeText = [NSString stringWithFormat:@"%@", @(unreadCount)];
    }
    return badgeText;
}

//- (void)setLcck_unreadCount:(NSInteger)lcck_unreadCount {
//    NSNumber *lcck_unreadCountObject = [NSNumber numberWithInteger:lcck_unreadCount];
//    objc_setAssociatedObject(self, @selector(lcck_unreadCount), lcck_unreadCountObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
//}

- (BOOL)lcck_mentioned
{
    return self.unreadMessagesMentioned;
}

//- (void)setLcck_mentioned:(BOOL)lcck_mentioned {
//    NSNumber *lcck_mentionedObject = [NSNumber numberWithBool:lcck_mentioned];
//    objc_setAssociatedObject(self, @selector(lcck_mentioned), lcck_mentionedObject, OBJC_ASSOCIATION_ASSIGN);
//}

- (NSString *)lcck_draft {
    return objc_getAssociatedObject(self, @selector(lcck_draft));
}

- (void)setLcck_draft:(NSString *)lcck_draft {
    objc_setAssociatedObject(self, @selector(lcck_draft), lcck_draft, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (LCCKConversationType)lcck_type {
    if (self.members.count == 2) {
        return LCCKConversationTypeSingle;
    }
    //系统对话按照群聊处理
    return LCCKConversationTypeGroup;
}

- (NSString *)lcck_displayName {
    BOOL disablePreviewUserId = [LCCKSettingService sharedInstance].isDisablePreviewUserId;
    NSString *displayName;
    if ([self lcck_type] == LCCKConversationTypeSingle) {
        NSString *peerId = [self lcck_peerId];
        NSError *error = nil;
        NSArray *peers = [[LCCKUserSystemService sharedInstance] getCachedProfilesIfExists:@[peerId] error:&error];
        id<LCCKUserDelegate> peer;
        if (peers.count > 0) {
            peer = peers[0];
        }
        displayName = peer.name ?: peerId;
        if (!peer.name && disablePreviewUserId) {
            NSString *defaultNickNameWhenNil = LCCKLocalizedStrings(@"nickNameIsNil");
            displayName = defaultNickNameWhenNil.length > 0 ? defaultNickNameWhenNil : @"";
        }
        return displayName;
    }
    if (self.name.length > 0) {
        return self.name;
    }
    if (self.members.count == 0) {
        return LCCKLocalizedStrings(@"SystemConversation");
    }
    return LCCKLocalizedStrings(@"GroupConversation");
    
}

- (NSString *)lcck_peerId {
    NSArray *members = self.members;
    if (members.count == 0) {
        [NSException raise:@"invalid conversation" format:@"invalid conversation"];
    }
    if (members.count == 1) {
        return members[0];
    }
    NSString *peerId;
    if ([members[0] isEqualToString:[LCCKSessionService sharedInstance].clientId]) {
        peerId = members[1];
    } else {
        peerId = members[0];
    }
    return peerId;
}

- (NSString *)lcck_title {
    NSString *displayName = self.lcck_displayName;
    if (!self.lcck_displayName || self.lcck_displayName.length == 0 ||  [self.lcck_displayName isEqualToString:LCCKLocalizedStrings(@"nickNameIsNil")]) {
        displayName = LCCKLocalizedStrings(@"Chat");
    }
    if (self.lcck_type == LCCKConversationTypeSingle || self.members.count == 0) {
        return displayName;
    } else {
        return [NSString stringWithFormat:@"%@(%ld)", displayName, (long)self.members.count];
        
    }
}

- (void)lcck_setConversationWithMute:(BOOL)mute callback:(LCCKBooleanResultBlock)callback {
    if (mute) {
        [self muteWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
            !callback ?: callback(succeeded, error);
        }];
    } else {
        [self unmuteWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
            !callback ?: callback(succeeded, error);
        }];
    }
}

- (BOOL)lcck_isCreaterForCurrentUser {
    BOOL isCreater = [self.creator isEqualToString:[LCChatKit sharedInstance].clientId];
    return isCreater;
}

@end

