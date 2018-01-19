//
//  LCCKConversationListService.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/22.
//  Copyright © 2016年 ElonChan . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKConstants.h"
#import "LCCKServiceDefinition.h"

@class AVIMConversation;

typedef void (^LCCKRecentConversationsCallback)(NSArray *conversations, NSInteger totalUnreadCount,  NSError *error);

@interface LCCKConversationListService : LCCKSingleton <LCCKConversationsListService>

typedef void(^LCCKPrepareConversationsWhenLoadBlock)(NSArray<AVIMConversation *> *conversations, LCCKBooleanResultBlock callback);
@property (nonatomic, copy, readonly) LCCKPrepareConversationsWhenLoadBlock prepareConversationsWhenLoadBlock;
- (void)setPrepareConversationsWhenLoadBlock:(LCCKPrepareConversationsWhenLoadBlock)prepareConversationsWhenLoadBlock;

- (void)findRecentConversationsWithBlock:(LCCKRecentConversationsCallback)block;

/**
 *  提供自定义行高的 Block
 */
typedef CGFloat (^LCCKHeightForRowBlock) (UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);
@property (nonatomic, copy, readonly) LCCKHeightForRowBlock heightForRowBlock;
- (void)setHeightForRowBlock:(LCCKHeightForRowBlock)heightForRowBlock;

/**
 *  提供自定义 Cell 的 Block，如果返回为 nil 则使用默认 Cell
 *  当使用自定义的 Cell 时，内部将不会处理 Cell，需要使用 configureCellBlock 自行配制 Cell
 */
typedef UITableViewCell* (^LCCKCellForRowBlock)(UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);
@property (nonatomic, copy, readonly) LCCKCellForRowBlock cellForRowBlock __deprecated_msg("LCCKCellForRowBlock is deprecated. Use <LCCKConversationListViewControllerDelegate> instead");
- (void)setCellForRowBlock:(LCCKCellForRowBlock)cellForRowBlock __deprecated_msg("LCCKCellForRowBlock is deprecated. Use <LCCKConversationListViewControllerDelegate> instead");

/**
 *  配置 Cell 的 Block，当默认的 Cell 或自定义的 Cell 需要配置时，该 block 将被调用
 */
typedef void (^LCCKConfigureCellBlock) (UITableViewCell *cell, UITableView *tableView, NSIndexPath *indexPath, AVIMConversation *conversation);
@property (nonatomic, copy, readonly) LCCKConfigureCellBlock configureCellBlock;
-(void)setConfigureCellBlock:(LCCKConfigureCellBlock)configureCellBlock;
- (void)fetchRelationConversationsFromServer:(AVIMArrayResultBlock)block;

@end
