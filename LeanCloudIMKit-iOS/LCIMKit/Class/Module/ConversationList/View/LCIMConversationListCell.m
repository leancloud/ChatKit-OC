//
//  LCIMConversationListCell.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCIMConversationListCell.h"
#import "JSBadgeView.h"
#import "LCIMKit.h"
#import "UIImageView+CornerRadius.h"

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
        cell = [[LCIMConversationListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[[self class] identifier]];
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
    [self.avatorImageView addSubview:self.badgeView];
    [self addSubview:self.timestampLabel];
    [self.contentView addSubview:self.litteBadgeView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.messageTextLabel];
}

- (UIImageView *)avatorImageView {
    if (_avatorImageView == nil) {
        UIImageView *avatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LCIMHorizontalSpacing, LCIMVerticalSpacing, LCIMImageSize, LCIMImageSize)];
        LCIMAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock = [LCIMKit sharedInstance].avatarImageViewCornerRadiusBlock;
        if (avatarImageViewCornerRadiusBlock) {
            CGFloat avatarImageViewCornerRadius = avatarImageViewCornerRadiusBlock(avatorImageView.frame.size);
            [avatorImageView zy_cornerRadiusAdvance:avatarImageViewCornerRadius rectCornerType:UIRectCornerAllCorners];

        }
        _avatorImageView = avatorImageView;
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
        _litteBadgeView = litteBadgeView;
    }
    return _litteBadgeView;
}

- (UILabel *)timestampLabel {
    if (_timestampLabel == nil) {
        UILabel *timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - LCIMHorizontalSpacing - LCIMTimestampeLabelWidth, CGRectGetMinY(_avatorImageView.frame), LCIMTimestampeLabelWidth, LCIMNameLabelHeight)];
        timestampLabel.font = [UIFont systemFontOfSize:13];
        timestampLabel.textAlignment = NSTextAlignmentRight;
        timestampLabel.textColor = [UIColor grayColor];
        _timestampLabel = timestampLabel;
    }
    return _timestampLabel;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_avatorImageView.frame) + LCIMHorizontalSpacing, CGRectGetMinY(_avatorImageView.frame), CGRectGetMinX(_timestampLabel.frame) - LCIMHorizontalSpacing * 3 - LCIMImageSize, LCIMNameLabelHeight)];
        nameLabel.font = [UIFont systemFontOfSize:17];
        _nameLabel = nameLabel;
    }
    return _nameLabel;
}

- (UILabel *)messageTextLabel {
    if (_messageTextLabel == nil) {
        UILabel *messageTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_nameLabel.frame), CGRectGetMaxY(_nameLabel.frame), CGRectGetWidth([UIScreen mainScreen].bounds)- 3 * LCIMHorizontalSpacing - LCIMImageSize, LCIMMessageLabelHeight)];
        messageTextLabel.backgroundColor = [UIColor clearColor];
        _messageTextLabel = messageTextLabel;
    }
    return _messageTextLabel;
}

- (JSBadgeView *)badgeView {
    if (_badgeView == nil) {
        JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.avatorImageView
                                                               alignment:JSBadgeViewAlignmentTopRight];
        [self.avatorImageView addSubview:(_badgeView = badgeView)];
        [self.avatorImageView bringSubviewToFront:_badgeView];
    }
    return _badgeView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.badgeView.badgeText = nil;
    self.badgeView = nil;
    self.litteBadgeView.hidden = YES;
    self.messageTextLabel.text = nil;
    self.timestampLabel.text = nil;
    self.nameLabel.text = nil;
}

@end
