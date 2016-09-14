//
//  RedpacketMessageCell.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//


#import "LCCKChatMessageCell.h"

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
