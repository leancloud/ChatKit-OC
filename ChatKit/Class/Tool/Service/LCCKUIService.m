//
//  LCCKUIService.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKUIService.h"

NSString *const LCCKUIServiceErrorDomain = @"LCCKUIServiceErrorDomain";

@interface LCCKUIService ()

@property (nonatomic, copy) LCCKPreviewImageMessageBlock previewImageMessageBlock;
@property (nonatomic, copy) LCCKPreviewLocationMessageBlock previewLocationMessageBlock;
@property (nonatomic, copy) LCCKOpenProfileBlock openProfileBlock;
@property (nonatomic, copy) LCCKUnreadCountChangedBlock unreadCountChangedBlock;
@property (nonatomic, assign, readwrite) LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock;
@property (nonatomic, copy, readwrite) LCCKLongPressMessageBlock longPressMessageBlock;

@end

@interface LCCKUIService ()

@property (nonatomic, copy) LCCKShowNotificationBlock showNotificationBlock;

@end

@implementation LCCKUIService

- (void)setPreviewImageMessageBlock:(LCCKPreviewImageMessageBlock)previewImageMessageBlock {
    _previewImageMessageBlock = previewImageMessageBlock;
}

- (void)setPreviewLocationMessageBlock:(LCCKPreviewLocationMessageBlock)previewLocationMessageBlock {
    _previewLocationMessageBlock = previewLocationMessageBlock;
}

- (void)setOpenProfileBlock:(LCCKOpenProfileBlock)openProfileBlock {
    _openProfileBlock = openProfileBlock;
}

- (void)setShowNotificationBlock:(LCCKShowNotificationBlock)showNotificationBlock {
    _showNotificationBlock = showNotificationBlock;
}

- (void)setUnreadCountChangedBlock:(LCCKUnreadCountChangedBlock)unreadCountChangedBlock {
    _unreadCountChangedBlock = unreadCountChangedBlock;
}

- (void)setAvatarImageViewCornerRadiusBlock:(LCCKAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock {
    _avatarImageViewCornerRadiusBlock = avatarImageViewCornerRadiusBlock;
}

- (void)setLongPressMessageBlock:(LCCKLongPressMessageBlock)longPressMessageBlock {
    _longPressMessageBlock = longPressMessageBlock;
}

@end
