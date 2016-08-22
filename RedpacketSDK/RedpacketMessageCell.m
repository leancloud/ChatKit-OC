//
//  RedpacketMessageCell.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-25.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketMessageCell.h"
#import "AVIMTypedMessageRedPacket.h"
#import "RedpacketMessageModel.h"

#define Redpacket_Message_Font_Size 14
#define Redpacket_SubMessage_Font_Size 12
#define Redpacket_Background_Extra_Height 25
#define Redpacket_SubMessage_Text NSLocalizedString(@"查看红包", @"查看红包")
#define Redpacket_Label_Padding 2

@implementation RedpacketMessageCell
@synthesize message = _message;
+ (void)load {
    [self registerCustomMessageCell];
}

+ (AVIMMessageMediaType)classMediaType {
    return 3;
}
- (void)setup{
    [self initialize];
    [super setup];
    [self addGeneralView];
    
}

- (void)updateConstraints{
    [super updateConstraints];
    [self.messageContentBackgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentView);
        make.height.equalTo(@(94));
        make.width.equalTo(@(200));
    }];
}

- (void)initialize {
    
    self.messageContentBackgroundImageView = [[UIImageView alloc]init];
    [self.contentView addSubview:self.messageContentBackgroundImageView];
    // 设置红包图标
    UIImage *icon = [self imageNamed:@"redPacket_redPacktIcon" ofBundle:@"RedpacketCellResource.bundle"];
    self.iconView = [[UIImageView alloc] initWithImage:icon];
    [self.messageContentBackgroundImageView addSubview:self.iconView];
    
    // 设置红包文字
    self.greetingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.greetingLabel.font = [UIFont systemFontOfSize:Redpacket_Message_Font_Size];
    self.greetingLabel.textColor = [UIColor whiteColor];
    self.greetingLabel.numberOfLines = 1;
    [self.greetingLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.greetingLabel setTextAlignment:NSTextAlignmentLeft];
    [self.messageContentBackgroundImageView addSubview:self.greetingLabel];
    
    // 设置次级文字
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.subLabel.text = Redpacket_SubMessage_Text;
    self.subLabel.font = [UIFont systemFontOfSize:Redpacket_SubMessage_Font_Size];
    self.subLabel.numberOfLines = 1;
    self.subLabel.textColor = [UIColor whiteColor];
    self.subLabel.numberOfLines = 1;
    [self.subLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.subLabel setTextAlignment:NSTextAlignmentLeft];
    [self.messageContentBackgroundImageView addSubview:self.subLabel];
    
    // 设置次级文字
    self.orgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.orgLabel.text = Redpacket_SubMessage_Text;
    self.orgLabel.font = [UIFont systemFontOfSize:Redpacket_SubMessage_Font_Size];
    self.orgLabel.numberOfLines = 1;
    self.orgLabel.textColor = [UIColor lightGrayColor];
    self.orgLabel.numberOfLines = 1;
    [self.orgLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.orgLabel setTextAlignment:NSTextAlignmentLeft];
    [self.messageContentBackgroundImageView addSubview:self.orgLabel];

    // 设置红包厂商图标
    icon = [self imageNamed:@"redPacket_yunAccount_icon" ofBundle:@"RedpacketCellResource.bundle"];
    self.orgIconView = [[UIImageView alloc] initWithImage:icon];
    [self.messageContentBackgroundImageView addSubview:self.orgIconView];
    
    CGRect rt = self.orgIconView.frame;
    rt.origin = CGPointMake(165, 75);
    rt.size = CGSizeMake(21, 14);
    self.orgIconView.frame = rt;
    self.orgLabel.frame = CGRectMake(13, 76, 150, 12);
    self.iconView.frame = CGRectMake(13, 19, 26, 34);
    self.greetingLabel.frame = CGRectMake(48, 19, 137, 15);
    CGRect frame = self.greetingLabel.frame;
    frame.origin.y = 41;
    self.subLabel.frame = frame;
    
}

- (UIImage*)imageNamed:(NSString*)imageNamed ofBundle:(NSString*)bundleName{
    NSString *resPath = [NSString stringWithFormat:@"%@/%@",bundleName,imageNamed];
    UIImage *image = [UIImage imageNamed:resPath];
    return image;
}

- (void)configureCellWithData:(AVIMTypedMessageRedPacket *)message{
    [super configureCellWithData:message];
    _message = message;
    NSDictionary * redpacketDictionary = message.attributes;
    
    RedpacketMessageModel *redpacketMessageModel = [RedpacketMessageModel redpacketMessageModelWithDic:redpacketDictionary];
    NSString *messageString = redpacketMessageModel.redpacket.redpacketGreeting;
    self.greetingLabel.text = messageString;
    
    NSString *orgString = redpacketMessageModel.redpacket.redpacketOrgName;
    self.orgLabel.text = orgString;
    
    switch (message.ioType) {
        case AVIMMessageIOTypeOut:{
                UIImage *image = [self imageNamed:@"redpacket_sender_bg" ofBundle:@"RedpacketCellResource.bundle"];
                self.messageContentBackgroundImageView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(70, 9, 25, 20)];
            }
            break;
        case AVIMMessageIOTypeIn:{
                UIImage *image = [self imageNamed:@"redpacket_receiver_bg" ofBundle:@"RedpacketCellResource.bundle"];
                self.messageContentBackgroundImageView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(70, 9, 25, 20)];
            }
            break;
        default:
            break;
    }
}
@end
