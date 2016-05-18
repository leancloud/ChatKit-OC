//
//  LCCKConversationListCell.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKConversationListCell.h"
#import "LCCKBadgeView.h"
#import "LCChatKit.h"
#import "UIImageView+LCCKExtension.h"

static CGFloat LCCKImageSize = 45;
static CGFloat LCCKVerticalSpacing = 8;
static CGFloat LCCKHorizontalSpacing = 10;
static CGFloat LCCKTimestampeLabelWidth = 100;

static CGFloat LCCKNameLabelHeightProportion = 3.0 / 5;
static CGFloat LCCKNameLabelHeight;
static CGFloat LCCKMessageLabelHeight;
static CGFloat LCCKLittleBadgeSize = 10;

CGFloat const LCCKConversationListCellDefaultHeight = 61; //LCCKImageSize + LCCKVerticalSpacing * 2;

@implementation LCCKConversationListCell

+ (instancetype)dequeueOrCreateCellByTableView :(UITableView *)tableView {
    LCCKConversationListCell *cell = [tableView dequeueReusableCellWithIdentifier:[LCCKConversationListCell identifier]];
    if (cell == nil) {
        cell = [[LCCKConversationListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[[self class] identifier]];
    }
    return cell;
}

+ (void)registerCellToTableView:(UITableView *)tableView {
    [tableView registerClass:[LCCKConversationListCell class] forCellReuseIdentifier:[[self class] identifier]];
}

+ (NSString *)identifier {
    return NSStringFromClass([LCCKConversationListCell class]);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    LCCKNameLabelHeight = LCCKImageSize * LCCKNameLabelHeightProportion;
    LCCKMessageLabelHeight = LCCKImageSize - LCCKNameLabelHeight;
    [self addSubview:self.avatorImageView];
    [self.avatorImageView addSubview:self.badgeView];
    [self addSubview:self.timestampLabel];
    [self.contentView addSubview:self.litteBadgeView];
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.messageTextLabel];
}

- (UIImageView *)avatorImageView {
    if (_avatorImageView == nil) {
        UIImageView *avatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LCCKHorizontalSpacing, LCCKVerticalSpacing, LCCKImageSize, LCCKImageSize)];
        LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock = [LCChatKit sharedInstance].avatarImageViewCornerRadiusBlock;
        if (avatarImageViewCornerRadiusBlock) {
            CGFloat avatarImageViewCornerRadius = avatarImageViewCornerRadiusBlock(avatorImageView.frame.size);
            [avatorImageView lcck_cornerRadiusAdvance:avatarImageViewCornerRadius rectCornerType:UIRectCornerAllCorners];

        }
        _avatorImageView = avatorImageView;
    }
    return _avatorImageView;
}

- (UIView *)litteBadgeView {
    if (_litteBadgeView == nil) {
        UIView *litteBadgeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, LCCKLittleBadgeSize, LCCKLittleBadgeSize)];
        litteBadgeView.backgroundColor = [UIColor redColor];
        litteBadgeView.layer.masksToBounds = YES;
        litteBadgeView.layer.cornerRadius = LCCKLittleBadgeSize / 2;
        litteBadgeView.center = CGPointMake(CGRectGetMaxX(_avatorImageView.frame), CGRectGetMinY(_avatorImageView.frame));
        litteBadgeView.hidden = YES;
        _litteBadgeView = litteBadgeView;
    }
    return _litteBadgeView;
}

- (UILabel *)timestampLabel {
    if (_timestampLabel == nil) {
        UILabel *timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds) - LCCKHorizontalSpacing - LCCKTimestampeLabelWidth, CGRectGetMinY(_avatorImageView.frame), LCCKTimestampeLabelWidth, LCCKNameLabelHeight)];
        timestampLabel.font = [UIFont systemFontOfSize:13];
        timestampLabel.textAlignment = NSTextAlignmentRight;
        timestampLabel.textColor = [UIColor grayColor];
        _timestampLabel = timestampLabel;
    }
    return _timestampLabel;
}

- (UILabel *)nameLabel {
    if (_nameLabel == nil) {
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_avatorImageView.frame) + LCCKHorizontalSpacing, CGRectGetMinY(_avatorImageView.frame), CGRectGetMinX(_timestampLabel.frame) - LCCKHorizontalSpacing * 3 - LCCKImageSize, LCCKNameLabelHeight)];
        nameLabel.font = [UIFont systemFontOfSize:17];
        _nameLabel = nameLabel;
    }
    return _nameLabel;
}

- (UILabel *)messageTextLabel {
    if (_messageTextLabel == nil) {
        UILabel *messageTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(_nameLabel.frame), CGRectGetMaxY(_nameLabel.frame), CGRectGetWidth([UIScreen mainScreen].bounds)- 3 * LCCKHorizontalSpacing - LCCKImageSize, LCCKMessageLabelHeight)];
        messageTextLabel.backgroundColor = [UIColor clearColor];
        _messageTextLabel = messageTextLabel;
    }
    return _messageTextLabel;
}

- (LCCKBadgeView *)badgeView {
    if (_badgeView == nil) {
        LCCKBadgeView *badgeView = [[LCCKBadgeView alloc] initWithParentView:self.avatorImageView
                                                               alignment:LCCKBadgeViewAlignmentTopRight];
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
