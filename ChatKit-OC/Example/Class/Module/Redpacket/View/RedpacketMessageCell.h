//
//  RedpacketMessageCell.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@interface RedpacketMessageCell : LCCKChatMessageCell<LCCKChatMessageCellSubclassing>

/**
 *  红包祝福语Lable
 */
@property(strong, nonatomic) UILabel *greetingLabel;

/**
 *  次级文字Lable
 */
@property(strong, nonatomic) UILabel *subLabel;

/**
 *  次级文字Lable
 */
@property(strong, nonatomic) UILabel *orgLabel;

/**
 *  红包图标
 */
@property(strong, nonatomic) UIImageView *iconView;

/**
 *  红包厂商图标
 */
@property(strong, nonatomic) UIImageView *orgIconView;

@end
