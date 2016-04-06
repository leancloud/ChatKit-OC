//
//  LCIMUIService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMUIService.h"

NSString *const LCIMUIServiceErrorDomain = @"LCIMUIServiceErrorDomain";

@interface LCIMUIService ()

@property (nonatomic, copy) LCIMPreviewImageMessageBlock previewImageMessageBlock;
@property (nonatomic, copy) LCIMPreviewLocationMessageBlock previewLocationMessageBlock;
@property (nonatomic, copy) LCIMOpenProfileBlock openProfileBlock;
@property (nonatomic, copy) LCIMUnreadCountChangedBlock unreadCountChangedBlock;
@end

@interface LCIMUIService ()

@property (nonatomic, copy) LCIMShowNotificationBlock showNotificationBlock;

@end

@implementation LCIMUIService

/**
 * create a singleton instance of LCIMUIService
 */
+ (instancetype)sharedInstance {
    static LCIMUIService *_sharedLCIMUIService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMUIService = [[self alloc] init];
    });
    return _sharedLCIMUIService;
}

- (void)setPreviewImageMessageBlock:(LCIMPreviewImageMessageBlock)previewImageMessageBlock {
    _previewImageMessageBlock = previewImageMessageBlock;
}

- (void)setPreviewLocationMessageBlock:(LCIMPreviewLocationMessageBlock)previewLocationMessageBlock {
    _previewLocationMessageBlock = previewLocationMessageBlock;
}

- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock {
    _openProfileBlock = openProfileBlock;
}

- (void)setShowNotificationBlock:(LCIMShowNotificationBlock)showNotificationBlock {
    _showNotificationBlock = showNotificationBlock;
}

- (void)setUnreadCountChangedBlock:(LCIMUnreadCountChangedBlock)unreadCountChangedBlock {
    _unreadCountChangedBlock = unreadCountChangedBlock;
}

@end
