//
//  RedpacketMessageCell.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//


#import "LCCKChatMessageCell.h"

@interface RedpacketMessageCell : LCCKChatMessageCell<LCCKChatMessageCellSubclassing>
@property(strong, nonatomic) UILabel *greetingLabel;
@property(strong, nonatomic) UILabel *subLabel; // 显示 "查看红包"
@property(strong, nonatomic) UILabel *orgLabel;
@property(strong, nonatomic) UIImageView *iconView;
@property(strong, nonatomic) UIImageView *orgIconView;

@property(nonatomic, strong) UIImageView *bubbleBackgroundView;

@end
