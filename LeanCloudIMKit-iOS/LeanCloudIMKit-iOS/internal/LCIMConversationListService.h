//
//  LCIMConversationListService.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
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

//TODO:
///**
// *  在没有数据时显示该view，占据Controller的View整个页面
// */
//@property (nonatomic, strong) UIView *viewForNoData;

+ (instancetype)sharedInstance;
- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds callback:(LCIMArrayResultBlock)callback;
- (void)findRecentConversationsWithBlock:(LCIMRecentConversationsCallback)block;

/**
 *  提供自定义行高的 Block
 */
typedef CGFloat (^LCIMHeightForRowBlock) (UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);
@property (nonatomic, copy, readonly) LCIMHeightForRowBlock heightForRowBlock;
- (void)setHeightForRowBlock:(LCIMHeightForRowBlock)heightForRowBlock;

/**
 *  提供自定义 Cell 的 Block，如果返回为 nil 则使用默认 Cell
 *  当使用自定义的 Cell 时，内部将不会处理 Cell，需要使用 configureCellBlock 自行配制 Cell
 */
typedef UITableViewCell* (^LCIMCellForRowBlock)(UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);
@property (nonatomic, copy, readonly) LCIMCellForRowBlock cellForRowBlock;
- (void)setCellForRowBlock:(LCIMCellForRowBlock)cellForRowBlock;

/**
 *  配置 Cell 的 Block，当默认的 Cell 或自定义的 Cell 需要配置时，该 block 将被调用
 */
typedef void (^LCIMConfigureCellBlock) (UITableViewCell *cell, UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);
@property (nonatomic, copy, readonly) LCIMConfigureCellBlock configureCellBlock;
-(void)setConfigureCellBlock:(LCIMConfigureCellBlock)configureCellBlock;

//TODO:
///**
// *  与会话列表关联的 UISearchBar
// */
//@property(nonatomic, readonly, strong) UISearchBar *searchBar;

@end
