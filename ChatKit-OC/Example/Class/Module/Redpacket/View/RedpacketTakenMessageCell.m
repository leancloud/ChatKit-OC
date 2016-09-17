//
//  RedpacketTakenMessageTipCell.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-27.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketTakenMessageCell.h"
#import "AVIMTypedMessageRedPacketTaken.h"
#import "RedpacketMessageModel.h"

#define BACKGROUND_LEFT_RIGHT_PADDING 10
#define ICON_LEFT_RIGHT_PADDING 2

@interface RedpacketTakenMessageCell ()

/**
 *  提示消息lable
 */
@property(strong, nonatomic) UILabel *tipMessageLabel;

@end

@implementation RedpacketTakenMessageCell
@synthesize message = _message;

+ (void)load {
    [self registerCustomMessageCell];
}

+ (AVIMMessageMediaType)classMediaType {
    return 4;
}

- (void)setup {
    [super setup];
    [self initialize];
    [self updateConstraintsIfNeeded];
}

- (void)initialize {
    self.contentView.backgroundColor = [UIColor clearColor];
    self.tipMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.tipMessageLabel.textAlignment = NSTextAlignmentCenter;
    self.tipMessageLabel.font = [UIFont systemFontOfSize:12];
    self.tipMessageLabel.textColor = [UIColor colorWithRed:158/255.0 green:158/255.0 blue:158/255.0 alpha:1];
    self.tipMessageLabel.userInteractionEnabled = NO;
    self.tipMessageLabel.numberOfLines = 1;
    [self.contentView addSubview:self.tipMessageLabel]; 
}

- (void)updateConstraints {
    [super updateConstraints];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(20));
        make.width.equalTo(@([UIScreen mainScreen].bounds.size.width));
    }];

    [self.tipMessageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
    }];
}

- (void)configureCellWithData:(AVIMTypedMessageRedPacketTaken *)message {
    [super configureCellWithData:message];
    if ([message isKindOfClass:[AVIMTypedMessageRedPacketTaken class]]){
        _message = (id)message;
        RedpacketMessageModel * rpModel = message.rpModel;
        NSString *tip = @"[云红包]";
        
        if([rpModel.currentUser.userId isEqualToString:rpModel.redpacketSender.userId]) {
            if ([rpModel.currentUser.userId isEqualToString:rpModel.redpacketReceiver.userId]) {
                tip = NSLocalizedString(@"你领取了自己的红包", @"你领取了自己的红包");
            }else {
                
                // 当前红包 SDK 不返回用户的昵称，需要 app 自己获取
                NSString * nikeName = (rpModel.redpacketReceiver.userNickname.length > 0)?rpModel.redpacketReceiver.userNickname:rpModel.redpacketReceiver.userId;
                // 收到了别人抢了我的红包的消息提示
                // XXX 领取了你的红包
                tip = [NSString stringWithFormat:@"%@%@",nikeName,NSLocalizedString(@"领取了你的红包", @"领取红包消息")];
            }
        } else {
            // 显示我抢了别人的红包的提示
            // 你领取了 XXX 的红包
            tip = [NSString stringWithFormat:@"%@%@%@",NSLocalizedString(@"你领取了", @"领取红包消息"),rpModel.redpacketSender.userNickname,NSLocalizedString(@"的红包", @"领取红包消息结尾")];
        }
        
        [self.tipMessageLabel setText:tip];
    }
    [self updateConstraintsIfNeeded];
    [self updateConstraints];
    [self layoutIfNeeded];
}

@end
