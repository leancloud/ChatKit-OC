//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "LCCKSettingItem.h"
#import "LCCKSettingCell.h"
#import "LCCKSettingButtonCell.h"
#import "LCCKSettingSwitchCell.h"

@implementation LCCKSettingItem

+ (LCCKSettingItem *) createItemWithTitle:(NSString *)title {
    LCCKSettingItem *item = [[LCCKSettingItem alloc] init];
    item.title = title;
    return item;
}

- (id) init {
    if (self = [super init]) {
        self.showDisclosureIndicator = YES;
    }
    return self;
}

- (NSString *) cellClassName {
    switch (self.type) {
        case LCCKSettingItemTypeDefalut:
            return NSStringFromClass([LCCKSettingCell class]);
            break;
        case LCCKSettingItemTypeTitleButton:
            return NSStringFromClass([LCCKSettingButtonCell class]);
            break;
        case LCCKSettingItemTypeSwitch:
            return NSStringFromClass([LCCKSettingSwitchCell class]);
            break;
        default:
            break;
    }
    return nil;
}

@end
