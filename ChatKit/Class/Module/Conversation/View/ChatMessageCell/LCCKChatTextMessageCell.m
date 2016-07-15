//
//  LCCKChatTextMessageCell.m
//  LCCKChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/13.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatTextMessageCell.h"

#import "Masonry.h"
#import "LCCKFaceManager.h"

@interface LCCKChatTextMessageCell ()

/**
 *  用于显示文本消息的文字
 */
@property (nonatomic, strong) UILabel *messageTextLabel;
@property (nonatomic, copy, readonly) NSDictionary *textStyle;

@end

@implementation LCCKChatTextMessageCell
@synthesize textStyle = _textStyle;

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    [self.messageTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentView).with.insets(UIEdgeInsetsMake(8, 16, 8, 16));
    }];
}

#pragma mark - Public Methods

- (void)setup {
    [self.messageContentView addSubview:self.messageTextLabel];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapMessageContentViewGestureRecognizerHandle:)];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    [self.messageContentView addGestureRecognizer:tapGestureRecognizer];
    [super setup];
}

- (void)configureCellWithData:(LCCKMessage *)message {
    [super configureCellWithData:message];
    NSMutableAttributedString *attrS = [LCCKFaceManager emotionStrWithString:message.text];
    [attrS addAttributes:self.textStyle range:NSMakeRange(0, attrS.length)];
    self.messageTextLabel.attributedText = attrS;
}

#pragma mark - Getters

- (UILabel *)messageTextLabel {
    if (!_messageTextLabel) {
        _messageTextLabel = [[UILabel alloc] init];
        _messageTextLabel.textColor = [UIColor blackColor];
        _messageTextLabel.font = [UIFont systemFontOfSize:16.0f];
        _messageTextLabel.numberOfLines = 0;
        _messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _messageTextLabel;
}

- (void)doubleTapMessageContentViewGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.delegate respondsToSelector:@selector(textMessageCellDoubleTapped:)]) {
            [self.delegate textMessageCellDoubleTapped:self];
        }
    }
}

- (NSDictionary *)textStyle {
    if (!_textStyle) {
        UIFont *font = [UIFont systemFontOfSize:14.0f];
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentLeft;
        style.paragraphSpacing = 0.25 * font.lineHeight;
        style.hyphenationFactor = 1.0;
        _textStyle = @{NSFontAttributeName: font,
                 NSParagraphStyleAttributeName: style};
    }
    return _textStyle;
}

//-(void)prepareForReuse {
//    [super prepareForReuse];
//    self.nicknameLabel = @"";
//    self.avatarButton = nil;
//}

@end
