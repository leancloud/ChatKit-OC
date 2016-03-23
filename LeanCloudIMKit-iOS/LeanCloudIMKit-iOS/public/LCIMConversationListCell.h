//
//  LCIMConversationListCell.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JSBadgeView;

@interface LCIMConversationListCell : UITableViewCell

@property (nonatomic, weak) UIImageView *avatorImageView;
@property (nonatomic, weak) UILabel *nameLabel;
@property (nonatomic, weak) UILabel  *messageTextLabel;
@property (nonatomic, weak) JSBadgeView *badgeView;
@property (nonatomic, weak) UIView *litteBadgeView;
@property (nonatomic, weak) UILabel *timestampLabel;
@property (nonatomic, copy) NSString *identifier;

+ (instancetype)dequeueOrCreateCellByTableView:(UITableView *)tableView;
+ (void)registerCellToTableView:(UITableView *)tableView;
- (void)prepareForReuse;

@end
