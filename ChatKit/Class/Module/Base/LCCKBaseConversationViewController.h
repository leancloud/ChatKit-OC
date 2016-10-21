//
//  LCCKBaseConversationViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/21.
//  Copyright © 2016年 ElonChan (wechat:chenyilong1010). All rights reserved.
//

#import "LCCKBaseTableViewController.h"

@class LCCKChatBar, LCCKConversationViewModel;

@interface LCCKBaseConversationViewController : LCCKBaseTableViewController

/**
 *  是否正在加载更多旧的消息数据
 */
@property (nonatomic, assign) BOOL loadingMoreMessage;
@property (nonatomic, weak) LCCKChatBar *chatBar;

/**
 *  判断是否支持下拉加载更多消息, 如果已经加载完所有消息，那么就可以设为NO。
 *
 *  @return 返回BOOL值，判定是否拥有这个功能
 */
@property (nonatomic, assign) BOOL shouldLoadMoreMessagesScrollToTop;

/*!
 * 发送消息时，会置YES
 * 输入框高度变更，比如输入文字换行、切换到 More、Face 页面、键盘弹出、键盘收缩
 */
@property (nonatomic, assign) BOOL allowScrollToBottom;
//somewhere in the header
@property (nonatomic, assign) CGFloat tableViewLastContentOffset;

/**
 *  是否滚动到底部
 *
 *  @param animated YES Or NO
 */
- (void)scrollToBottomAnimated:(BOOL)animated;

- (void)loadMoreMessagesScrollTotop;
/**
 *  判断是否用户手指滚动
 */
@property (nonatomic, assign) BOOL isUserScrolling;

@end
