//
//  LCCKUIService.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKUIService.h"

NSString *const LCCKUIServiceErrorDomain = @"LCCKUIServiceErrorDomain";

@implementation LCCKUIService
@synthesize openProfileBlock = _openProfileBlock;
@synthesize previewImageMessageBlock = _previewImageMessageBlock;
@synthesize previewLocationMessageBlock = _previewLocationMessageBlock;
@synthesize longPressMessageBlock = _longPressMessageBlock;
@synthesize showNotificationBlock = _showNotificationBlock;
@synthesize HUDActionBlock = _HUDActionBlock;
@synthesize avatarImageViewCornerRadiusBlock = _avatarImageViewCornerRadiusBlock;

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

- (void)setHUDActionBlock:(LCCKHUDActionBlock)HUDActionBlock {
    _HUDActionBlock = HUDActionBlock;
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
