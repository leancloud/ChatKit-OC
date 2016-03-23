//
//  LCIMConversationListCell.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMConversationListCell.h"
#import "JSBadgeView.h"

static CGFloat LCIMImageSize = 45;
static CGFloat LCIMVerticalSpacing = 8;
static CGFloat LCIMHorizontalSpacing = 10;
static CGFloat LCIMTimestampeLabelWidth = 100;

static CGFloat LCIMNameLabelHeightProportion = 3.0 / 5;
static CGFloat LCIMNameLabelHeight;
static CGFloat LCIMMessageLabelHeight;
static CGFloat LCIMLittleBadgeSize = 10;

CGFloat const LCIMConversationListCellDefaultHeight = 61; //LCIMImageSize + LCIMVerticalSpacing * 2;

@implementation LCIMConversationListCell

+ (instancetype)dequeueOrCreateCellByTableView :(UITableView *)tableView {
    LCIMConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:[LCIMConversationListCell identifier]];
    if (cell == nil) {
        cell = [[LCIMConversationListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[[self class] identifier]];
    }
    return cell;
}

+ (void)registerCellToTableView:(UITableView *)tableView {
    [tableView registerClass:[LCIMConversationListCell class] forCellReuseIdentifier:[[self class] identifier]];
}

+ (NSString *)identifier {
    return NSStringFromClass([LCIMConversationListCell class]);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    LCIMNameLabelHeight = LCIMImageSize * LCIMNameLabelHeightProportion;
    LCIMMessageLabelHeight = LCIMImageSize - LCIMNameLabelHeight;
    [self addSubview:self.avatorImageView];
    [self addSubview:self.timestampLabel];
    [self addSubview:self.litteBadgeView];
    [self addSubview:self.nameLabel];
    [self addSubview:self.messageTextLabel];
}

- (UIImageView *)avatorImageView {
    if (_avatorImageView == nil) {
        UIImageView *avatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LCIMHorizontalSpacing, LCIMVerticalSpacing, LCIMImageSize, LCIMImageSize)];
        [self addSubview:(_avatorImageView = avatorImageView)];
    }
    return _avatorImageView;
}

- (UIView *)litteBadgeView {
    if (_litteBadgeView == nil) {
        UIView *litteBadgeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, LCIMLittleBadgeSize, LCIMLittleBadgeSize)];
        litteBadgeView.backgroundColor = [UIColor redColor];
        litteBadgeView.layer.masksToBounds = YES;
        litteBadgeView.layer.cornerRadius = LCIMLittleBadgeSize / 2;
        litteBadgeView.center = CGPointMake(CGRectGetMaxX(_avatorImageView.frame), CGRectGetMinY(_avatorImageView.frame));
        litteBadgeView.hidden = YES;
        [self addSubview:(_litteBadgeView = litteBadgeView)];
    }
    return _litteBadgeView;
}

- (UILabel *)timestampLabel {
    if (_timestampLabel == nil) {
        UILabel *timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - LCIMHorizontalSpacing - LCIMTimestampeLabelWidth, CGRectGetMinY(_avatorImageView.frame), LCIMTimestampeLabelWidth, LCIMNameLabelHeight)];
        timestampLabel.font = [UIFont systemFontOfSize:13];
        timestampLabel.textAlignment = NSTextAlignmentRight;
        timestampLabel.textColor = [UIColor grayColor];
        [self addSubview:(_timestampLabel = timestampLabel)];
    }
    return _timestampLabel;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_avatorImageView.frame) + LCIMHorizontalSpacing, CGRectGetMinY(_avatorImageView.frame), CGRectGetMinX(_timestampLabel.frame) - LCIMHorizontalSpacing * 3 - LCIMImageSize, LCIMNameLabelHeight)];
        nameLabel.font = [UIFont systemFontOfSize:17];
        [self addSubview:(_nameLabel = nameLabel)];
    }
    return _nameLabel;
}

- (UILabel *)messageTextLabel {
    if (_messageTextLabel == nil) {
        UILabel *messageTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_nameLabel.frame), CGRectGetMaxY(_nameLabel.frame), CGRectGetWidth([UIScreen mainScreen].bounds)- 3 * LCIMHorizontalSpacing - LCIMImageSize, LCIMMessageLabelHeight)];
        messageTextLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:(_messageTextLabel = messageTextLabel)];
    }
    return _messageTextLabel;
}

- (JSBadgeView *)badgeView {
    if (_badgeView == nil) {
        JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:_avatorImageView alignment:JSBadgeViewAlignmentTopRight];
        [self addSubview:(_badgeView = badgeView)];
    }
    return _badgeView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.badgeView.badgeText = nil;
    self.litteBadgeView.hidden = YES;
    self.messageTextLabel.text = nil;
    self.timestampLabel.text = nil;
    self.nameLabel.text = nil;
}

@end
