//
//  AVIMConversation+LCCKExtension.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "AVIMConversation+LCCKExtension.h"
#import <objc/runtime.h>
#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"
#import "LCCKUserDelegate.h"

@implementation AVIMConversation (LCCKExtension)

- (AVIMTypedMessage *)lcck_lastMessage {
    return objc_getAssociatedObject(self, @selector(lcck_lastMessage));
}

- (void)setLcck_lastMessage:(AVIMTypedMessage *)lcck_lastMessage {
    objc_setAssociatedObject(self, @selector(lcck_lastMessage), lcck_lastMessage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)lcck_unreadCount {
    NSNumber *lcck_unreadCountObject = objc_getAssociatedObject(self, @selector(lcck_unreadCount));
    return [lcck_unreadCountObject intValue];
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

- (void)setLcck_unreadCount:(NSInteger)lcck_unreadCount {
    NSNumber *lcck_unreadCountObject = [NSNumber numberWithInteger:lcck_unreadCount];
    objc_setAssociatedObject(self, @selector(lcck_unreadCount), lcck_unreadCountObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)lcck_mentioned {
    NSNumber *lcck_mentionedObject = objc_getAssociatedObject(self, @selector(lcck_mentioned));
    return [lcck_mentionedObject boolValue];
}

- (void)setLcck_mentioned:(BOOL)lcck_mentioned {
    NSNumber *lcck_mentionedObject = [NSNumber numberWithBool:lcck_mentioned];
    objc_setAssociatedObject(self, @selector(lcck_mentioned), lcck_mentionedObject, OBJC_ASSOCIATION_ASSIGN);
}

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

- (void)lcck_setObject:(id)object forKey:(NSString *)key callback:(LCCKBooleanResultBlock)callback {
    AVIMConversationUpdateBuilder *updateBuilder = [self newUpdateBuilder] ;
    updateBuilder.attributes = self.attributes;
    [updateBuilder setObject:object forKey:key];
    [self update:[updateBuilder dictionary] callback:callback];
}

- (void)lcck_removeObjectForKey:(NSString *)key callback:(LCCKBooleanResultBlock)callback {
    AVIMConversationUpdateBuilder *updateBuilder = [self newUpdateBuilder] ;
    updateBuilder.attributes = self.attributes;
    [updateBuilder removeObjectForKey:key];
    [self update:[updateBuilder dictionary] callback:callback];
}

@end

