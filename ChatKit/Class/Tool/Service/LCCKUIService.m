//
//  LCCKUIService.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/1.
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
    _previewImageMessageBlock = [previewImageMessageBlock copy];
}

- (void)setPreviewLocationMessageBlock:(LCCKPreviewLocationMessageBlock)previewLocationMessageBlock {
    _previewLocationMessageBlock = [previewLocationMessageBlock copy];
}

- (void)setOpenProfileBlock:(LCCKOpenProfileBlock)openProfileBlock {
    _openProfileBlock = [openProfileBlock copy];
}

- (void)setShowNotificationBlock:(LCCKShowNotificationBlock)showNotificationBlock {
    _showNotificationBlock = [showNotificationBlock copy];
}

- (void)setHUDActionBlock:(LCCKHUDActionBlock)HUDActionBlock {
    _HUDActionBlock = [HUDActionBlock copy];
}

- (void)setUnreadCountChangedBlock:(LCCKUnreadCountChangedBlock)unreadCountChangedBlock {
    _unreadCountChangedBlock = [unreadCountChangedBlock copy];
}

- (void)setAvatarImageViewCornerRadiusBlock:(LCCKAvatarImageViewCornerRadiusBlock)avatarImageViewCornerRadiusBlock {
    _avatarImageViewCornerRadiusBlock = [avatarImageViewCornerRadiusBlock copy];
}

- (void)setLongPressMessageBlock:(LCCKLongPressMessageBlock)longPressMessageBlock {
    _longPressMessageBlock = [longPressMessageBlock copy];
}

@end
