//
//  LCCKConversationListViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKBaseTableViewController.h"

@class AVIMConversation;

@protocol LCCKConversationListViewControllerDelegate <NSObject>

@optional
/**
 实现代理方法,可获得到cell点击事件的回调
 */
- (void)conversation:(AVIMConversation *)conversation tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 实现代理方法,当默认的 Cell 或自定义的 Cell 需要配置时，该代理将被调用
 */
- (void)conversation:(AVIMConversation *)conversation cell:(UITableViewCell *)cell tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end
/**
 *  对话列表 Cell 的默认高度
 */
FOUNDATION_EXTERN const CGFloat LCCKConversationListCellDefaultHeight;

@interface LCCKConversationListViewController : LCCKBaseTableViewController

@property (nonatomic, weak) id<LCCKConversationListViewControllerDelegate> delegate;

- (void)refresh;

@end

