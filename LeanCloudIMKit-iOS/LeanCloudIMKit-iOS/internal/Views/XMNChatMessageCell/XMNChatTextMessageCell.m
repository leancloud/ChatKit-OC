//
//  XMNChatTextMessageCell.m
//  XMNChatExample
//
//  Created by shscce on 15/11/13.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNChatTextMessageCell.h"

#import "Masonry.h"
#import "XMFaceManager.h"

@interface XMNChatTextMessageCell ()

/**
 *  用于显示文本消息的文字
 */
@property (nonatomic, strong) UILabel *messageTextL;
@property (nonatomic, copy, readonly) NSDictionary *textStyle;

@end

@implementation XMNChatTextMessageCell
@synthesize textStyle = _textStyle;

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    [self.messageTextL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentV).with.insets(UIEdgeInsetsMake(8, 16, 8, 16));
    }];
}

#pragma mark - Public Methods

- (void)setup {
    
    [self.messageContentV addSubview:self.messageTextL];
    [super setup];
    
}

- (void)configureCellWithData:(id)data {
    [super configureCellWithData:data];

    NSMutableAttributedString *attrS = [XMFaceManager emotionStrWithString:data[kXMNMessageConfigurationTextKey]];
    [attrS addAttributes:self.textStyle range:NSMakeRange(0, attrS.length)];
    self.messageTextL.attributedText = attrS;
    
}

#pragma mark - Getters

- (UILabel *)messageTextL {
    if (!_messageTextL) {
        _messageTextL = [[UILabel alloc] init];
        _messageTextL.textColor = [UIColor blackColor];
        _messageTextL.font = [UIFont systemFontOfSize:16.0f];
        _messageTextL.numberOfLines = 0;
        _messageTextL.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _messageTextL;
}

- (NSDictionary *)textStyle {
    if (!_textStyle) {
        UIFont *font = [UIFont systemFontOfSize:14.0f];
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = self.messageOwner == XMNMessageOwnerSelf ? NSTextAlignmentRight : NSTextAlignmentLeft;
        style.paragraphSpacing = 0.25 * font.lineHeight;
        style.hyphenationFactor = 1.0;
        _textStyle = @{NSFontAttributeName: font,
                 NSParagraphStyleAttributeName: style};
    }
    return _textStyle;
    
}

@end
