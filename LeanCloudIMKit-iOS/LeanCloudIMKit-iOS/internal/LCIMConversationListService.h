//
//  LCIMConversationListService.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMConstants.h"
#import "LCIMServiceDefinition.h"

@class AVIMConversation;


typedef void(^LCIMMarkBadgeWithTotalUnreadCountBlock)(NSInteger totalUnreadCount);
typedef void(^LCIMPrepareConversationsWhenLoadBlock)(NSArray<AVIMConversation *> *conversations, LCIMBooleanResultBlock callback);
typedef void (^LCIMRecentConversationsCallback)(NSArray *conversations, NSInteger totalUnreadCount,  NSError *error);

@interface LCIMConversationListService : NSObject <LCIMConversationsListService>

@property (nonatomic, copy, readonly) LCIMMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock;

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCIMMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock;

@property (nonatomic, copy, readonly) LCIMPrepareConversationsWhenLoadBlock prepareConversationsWhenLoadBlock;

- (void)setPrepareConversationsWhenLoadBlock:(LCIMPrepareConversationsWhenLoadBlock)prepareConversationsWhenLoadBlock;

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

/**
 *  在没有数据时显示该view，占据Controller的View整个页面
 */
@property (nonatomic, strong) UIView *viewForNoData;

+ (instancetype)sharedInstance;
- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds callback:(LCIMArrayResultBlock)callback;
- (void)findRecentConversationsWithBlock:(LCIMRecentConversationsCallback)block;

/**
 *  提供自定义行高的 Block，其中 tableView 和 indexPath 可能为搜索列表的对象
 */
@property (nonatomic, copy) CGFloat (^LCIMHeightForRowBlock) (UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);

/**
 *  提供自定义 Cell 的 Block，如果返回为 nil 则使用默认 Cell
 *  当使用自定义的 Cell 时，内部将不会处理 Cell，需要使用 configureCellBlock 自行配制 Cell
 */
@property (nonatomic, copy) UITableViewCell* (^LCIMCellForRowBlock)(UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);

/**
 *  配置 Cell 的 Block，当默认的 Cell 或自定义的 Cell 需要配置时，该 block 将被调用
 */
@property (nonatomic, copy) void (^LCIMConfigureCellBlock) (UITableViewCell *cell, UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);

/**
 *  与会话列表关联的 UISearchBar
 */
@property(nonatomic, readonly, strong) UISearchBar *searchBar;

@end
