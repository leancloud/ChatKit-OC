//
//  XMNChatSystemMessageCell.m
//  XMNChatExample
//
//  Created by shscce on 15/11/17.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNChatSystemMessageCell.h"

#import "Masonry.h"

@interface XMNChatSystemMessageCell ()

@property (nonatomic, weak) UILabel *systemMessageL;
@property (nonatomic, strong) UIView *systemMessageContentV;
@property (nonatomic, strong, readonly) NSDictionary *systemMessageStyle;

@end

@implementation XMNChatSystemMessageCell
@synthesize systemMessageStyle = _systemMessageStyle;

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    [self.systemMessageContentV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).with.offset(8);
        make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-8);
        make.width.lessThanOrEqualTo(@([UIApplication sharedApplication].keyWindow.frame.size.width/5*3));
        make.centerX.equalTo(self.contentView.mas_centerX);
        
    }];
    
}

#pragma mark - Public Methods

- (void)setup {
    
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.systemMessageContentV];

    [self updateConstraintsIfNeeded];
}

- (void)configureCellWithData:(id)data {
    [super configureCellWithData:data];

    self.systemMessageL.attributedText = [[NSAttributedString alloc] initWithString:data[kXMNMessageConfigurationTextKey] attributes:self.systemMessageStyle];
    
}


#pragma mark - Getters

- (UIView *)systemMessageContentV {
    if (!_systemMessageContentV) {
        _systemMessageContentV = [[UIView alloc] init];
        _systemMessageContentV.backgroundColor = [UIColor lightGrayColor];
        _systemMessageContentV.alpha = .8f;
        _systemMessageContentV.layer.cornerRadius = 6.0f;
        _systemMessageContentV.translatesAutoresizingMaskIntoConstraints = NO;

        UILabel *systemMessageL = [[UILabel alloc] init];
        systemMessageL.numberOfLines = 0;
        
        [_systemMessageContentV addSubview:self.systemMessageL = systemMessageL];
        [systemMessageL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_systemMessageContentV).with.insets(UIEdgeInsetsMake(8, 16, 8, 16));
        }];
        
        systemMessageL.attributedText = [[NSAttributedString alloc] initWithString:@"2015-11-16" attributes:self.systemMessageStyle];
    }
    return _systemMessageContentV;
}

- (NSDictionary *)systemMessageStyle {
    if (!_systemMessageStyle) {
        UIFont *font = [UIFont systemFontOfSize:14];
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.paragraphSpacing = 0.15 * font.lineHeight;
        style.hyphenationFactor = 1.0;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.alignment = NSTextAlignmentCenter;
        _systemMessageStyle = @{
                 NSFontAttributeName: font,
                 NSParagraphStyleAttributeName: style,
                 NSForegroundColorAttributeName: [UIColor whiteColor]
                 };
    }
    return _systemMessageStyle;
}


@end
