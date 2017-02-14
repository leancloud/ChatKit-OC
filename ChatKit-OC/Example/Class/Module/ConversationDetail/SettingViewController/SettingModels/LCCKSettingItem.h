//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import <Foundation/Foundation.h>

@interface LCCKSettingItem : NSObject

#define     LCCKCreateSettingItem(title) [LCCKSettingItem createItemWithTitle:title]

typedef NS_ENUM(NSInteger, LCCKSettingItemType) {
    LCCKSettingItemTypeDefalut = 0,
    LCCKSettingItemTypeTitleButton,
    LCCKSettingItemTypeSwitch,
    LCCKSettingItemTypeOther,
};

/**
 *  主标题
 */
@property (nonatomic, strong) NSString *title;

/**
 *  副标题
 */
@property (nonatomic, strong) NSString *subTitle;

/**
 *  右图片(本地)
 */
@property (nonatomic, strong) NSString *rightImagePath;

/**
 *  右图片(网络)
 */
@property (nonatomic, strong) NSString *rightImageURL;

/**
 *  是否显示箭头（默认YES）
 */
@property (nonatomic, assign) BOOL showDisclosureIndicator;

/**
 *  停用高亮（默认NO）
 */
@property (nonatomic, assign) BOOL disableHighlight;
@property (nonatomic, assign) BOOL isSwithOn;

/**
 *  cell类型，默认default
 */
@property (nonatomic, assign) LCCKSettingItemType type;

+ (LCCKSettingItem *)createItemWithTitle:(NSString *)title;

- (NSString *)cellClassName;

@end
