//
//  RedpacketTakenMessageTipCell.h
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-27.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import <RongIMKit/RongIMKit.h>
#define REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING 20
#define REDPACKET_MESSAGE_TOP_BOTTOM_PADDING 40

@interface RedpacketTakenMessageTipCell : RCMessageBaseCell
@property(strong, nonatomic) RCTipLabel *tipMessageLabel;
@property(strong, nonatomic) UIImageView *iconView;

+ (CGSize)sizeForModel:(RCMessageModel*)model;
@end
