//
//  LCIMConversationListViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCIMBaseTableViewController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

/**
 *  选中某个会话后的回调
 *  @param conversation 被选中的会话
 */
typedef void(^LCIMConversationsListDidSelectItemBlock)(AVIMConversation *conversation);

@interface LCIMConversationListViewController : LCIMBaseTableViewController

/**
 *  选中某个会话后的回调
 */
@property (nonatomic, copy, readonly) LCIMConversationsListDidSelectItemBlock didSelectItemBlock;

/**
 *  设置选中某个会话后的回调
 */
- (void)setDidSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)didSelectItemBlock;

/**
 *  删除某个会话后的回调
 *  @param conversation 被选中的会话
 */
typedef void(^LCIMConversationsListDidDeleteItemBlock)(AVIMConversation *conversation);

/**
 *  删除某个会话后的回调
 */
@property (nonatomic, copy, readonly) LCIMConversationsListDidDeleteItemBlock didDeleteItemBlock;

/**
 *  设置删除某个会话后的回调
 */
- (void)setDidDeleteItemBlock:(LCIMConversationsListDidSelectItemBlock)didDeleteItemBlock;

/**
 *  设置某个会话的最近消息内容后的回调
 *  @param conversation 需要设置最近消息内容的会话
 *  @return 无需自定义最近消息内容返回nil
 */
typedef NSString *(^LCIMConversationsLatestMessageContent)(AVIMConversation *conversation);

/**
 *  设置某个会话的最近消息内容后的回调
 */
@property (nonatomic, copy, readonly) LCIMConversationsLatestMessageContent latestMessageContentBlock;

/**
 *  设置某个会话的最近消息内容后的回调
 */
- (void)setLatestMessageContentBlock:(LCIMConversationsLatestMessageContent)latestMessageContentBlock;

@end

@interface LCIMConversationListViewController ()

/**
 *  在没有数据时显示该view，占据Controller的View整个页面
 */
@property (nonatomic, strong) UIView *viewForNoData;

/*
 *  会话左滑菜单设置block
 *  @return  需要显示的菜单数组
 *  @param conversation, 会话
 *  @param editActions, 默认的菜单数组，成员为LCIMMoreActionItem类型
 */
typedef NSArray *(^LCIMConversationEditActionsBlock)(AVIMConversation *conversation, NSArray *editActions);

/**
 *  可以通过这个block设置会话列表中每个会话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
@property (nonatomic, copy) LCIMConversationEditActionsBlock conversationEditActionBlock;

/**
 *  提供自定义行高的 Block，其中 tableView 和 indexPath 可能为搜索列表的对象
 */
@property (nonatomic, copy) CGFloat (^heightForRowBlock) (UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);

/**
 *  会话列表 Cell 的默认高度
 */
FOUNDATION_EXTERN const CGFloat LCIMConversationListCellDefaultHeight;

/**
 *  提供自定义 Cell 的 Block，如果返回为 nil 则使用默认 Cell
 *  当使用自定义的 Cell 时，内部将不会处理 Cell，需要使用 configureCellBlock 自行配制 Cell
 */
@property (nonatomic, copy) UITableViewCell* (^cellForRowBlock)(UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);

/**
 *  配置 Cell 的 Block，当默认的 Cell 或自定义的 Cell 需要配置时，该 block 将被调用
 */
@property (nonatomic, copy) void (^configureCellBlock) (UITableViewCell *cell, UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);

@end

@interface LCIMConversationListViewController (LCIMSearchSupport)

/**
 *  与会话列表关联的 UISearchBar
 */
@property(nonatomic, readonly, strong) UISearchBar *searchBar;

@end
