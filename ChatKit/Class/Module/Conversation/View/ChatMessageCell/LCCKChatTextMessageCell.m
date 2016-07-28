//
//  LCCKChatTextMessageCell.m
//  LCCKChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/13.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

static CGFloat LCCK_MSG_SPACE_TOP = 16;
static CGFloat LCCK_MSG_SPACE_BTM = 16;
static CGFloat LCCK_MSG_SPACE_LEFT = 16;
static CGFloat LCCK_MSG_SPACE_RIGHT = 16;
static CGFloat LCCK_MSG_TEXT_FONT_SIZE = 14;

#define SHOW_SIMPLE_TIPS(m) [[[UIAlertView alloc] initWithTitle:@"" message:(m) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
#define LCCK_TEXT_MSG_CELL_TEXT_COLOR [UIColor blackColor]

#import "LCCKChatTextMessageCell.h"
#import "Masonry.h"
#import "LCCKFaceManager.h"
#import "LCCKWebViewController.h"

@interface LCCKChatTextMessageCell ()

/**
 *  用于显示文本消息的文字
 */
@property (nonatomic, strong) MLLinkLabel *messageTextLabel;
@property (nonatomic, copy, readonly) NSDictionary *textStyle;
@property (nonatomic, strong) NSArray *expressionData;

@end

@implementation LCCKChatTextMessageCell
@synthesize textStyle = _textStyle;

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    [self.messageTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentView).with.insets(UIEdgeInsetsMake(LCCK_MSG_SPACE_TOP, LCCK_MSG_SPACE_LEFT, LCCK_MSG_SPACE_BTM, LCCK_MSG_SPACE_RIGHT));
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

- (MLLinkLabel *)messageTextLabel {
    if (!_messageTextLabel) {
        _messageTextLabel = [[MLLinkLabel alloc] init];
        _messageTextLabel.textColor = LCCK_TEXT_MSG_CELL_TEXT_COLOR;
        _messageTextLabel.font = [UIFont systemFontOfSize:LCCK_MSG_TEXT_FONT_SIZE];
        _messageTextLabel.numberOfLines = 0;
        _messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _messageTextLabel.linkTextAttributes = @{NSForegroundColorAttributeName:[UIColor blueColor]};
        _messageTextLabel.activeLinkTextAttributes = @{NSForegroundColorAttributeName:[UIColor blueColor],NSBackgroundColorAttributeName:kDefaultActiveLinkBackgroundColorForMLLinkLabel};
        
        [_messageTextLabel setDidClickLinkBlock:^(MLLink *link, NSString *linkText, MLLinkLabel *label) {
            NSString *tips = [NSString stringWithFormat:@"Click\nlinkType:%ld\nlinkText:%@\nlinkValue:%@",link.linkType,linkText,link.linkValue];
            if ([self.delegate respondsToSelector:@selector(messageCell:didTapLinkText:linkType:)]) {
                [self.delegate messageCell:self didTapLinkText:linkText linkType:link.linkType];
            }
        }];
        
    }
    return _messageTextLabel;
}

- (void)tap
{
    SHOW_SIMPLE_TIPS(@"tapped");
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
        UIFont *font = [UIFont systemFontOfSize:LCCK_MSG_TEXT_FONT_SIZE];
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
