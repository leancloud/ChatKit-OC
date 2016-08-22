//
//  RedpacketTakenMessageTipCell.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-4-27.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketTakenMessageTipCell.h"
#import "UIColor+RCColor.h"

#define BACKGROUND_LEFT_RIGHT_PADDING 10
#define ICON_LEFT_RIGHT_PADDING 2

@interface RedpacketTakenMessageTipCell ()
@property(strong, nonatomic) UIView *bgView;
@end

@implementation RedpacketTakenMessageTipCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    
    self.baseContentView.backgroundColor = [UIColor clearColor];
    
    self.bgView = [[UIView alloc] initWithFrame:self.baseContentView.bounds];
    self.bgView.userInteractionEnabled = NO;
    self.bgView.backgroundColor = [UIColor colorWithHexString:@"dddddd" alpha:1.0];
    self.bgView.layer.cornerRadius = 4.0f;
    [self.baseContentView addSubview:self.bgView];
    
    self.tipMessageLabel = [[RCTipLabel alloc] initWithFrame:CGRectZero];
    self.tipMessageLabel.font = [UIFont systemFontOfSize:12];
    self.tipMessageLabel.textColor = [UIColor colorWithHexString:@"9e9e9e" alpha:1.0];
    self.tipMessageLabel.userInteractionEnabled = NO;
    self.tipMessageLabel.numberOfLines = 1;
    [self.bgView addSubview:self.tipMessageLabel];
    
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 15)];
    self.iconView.image = [RCKitUtility imageNamed:@"redpacket_smallIcon" ofBundle:@"RedpacketCellResource.bundle"];
    self.iconView.userInteractionEnabled = NO;
    [self.bgView addSubview:self.iconView];
    
    self.isDisplayReadStatus = NO;
    
}

- (void)setDataModel:(RCMessageModel *)model {
    [super setDataModel:model];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.tipMessageLabel sizeToFit];
    
    CGRect frame = self.tipMessageLabel.frame;
    CGRect iconFrame = self.iconView.frame;
    CGRect bgFrame = CGRectMake(0, 0,
                                frame.size.width + iconFrame.size.width + 2 * BACKGROUND_LEFT_RIGHT_PADDING,
                                22);
    
    frame.origin.y = (bgFrame.size.height - frame.size.height) * 0.5;
    iconFrame.origin.x = BACKGROUND_LEFT_RIGHT_PADDING - ICON_LEFT_RIGHT_PADDING;
    iconFrame.origin.y = frame.origin.y + (frame.size.height - iconFrame.size.height) * 0.5;
    self.iconView.frame = iconFrame;
    
    frame.origin.x = ICON_LEFT_RIGHT_PADDING + iconFrame.origin.x + iconFrame.size.width;
    self.tipMessageLabel.frame = frame;
    
    
    bgFrame.origin.y = REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING;
    bgFrame.origin.x = (self.baseContentView.bounds.size.width - bgFrame.size.width) * 0.5;
    
    self.bgView.frame = bgFrame;
}

+ (CGSize)sizeForModel:(RCMessageModel *)model
{
    return CGSizeMake(320, 22);
}

@end
