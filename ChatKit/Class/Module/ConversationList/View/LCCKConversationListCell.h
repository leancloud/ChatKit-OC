//
//  LCCKConversationListCell.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/22.
//  Copyright © 2016年 ElonChan (wechat:chenyilong1010). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LCCKBadgeView.h"

@interface LCCKConversationListCell : UITableViewCell

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel  *messageTextLabel;
@property (nonatomic, strong) LCCKBadgeView *badgeView;
@property (nonatomic, strong) UIView *litteBadgeView;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, strong) UIButton *remindMuteImageView;

@property (nonatomic, copy) NSString *identifier;

+ (instancetype)dequeueOrCreateCellByTableView:(UITableView *)tableView;
+ (void)registerCellToTableView:(UITableView *)tableView;

@end
