//
//  LCCKBaseConversationViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//
#define LCCKDebugging 1
#import "LCCKBaseConversationViewController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKCellRegisterController.h"
#import "LCCKChatBar.h"
#import "MJRefresh.h"
#import "LCCKConversationRefreshHeader.h"
static void * const LCCKBaseConversationViewControllerRefreshContext = (void*)&LCCKBaseConversationViewControllerRefreshContext;

@interface LCCKBaseConversationViewController ()

@end

@implementation LCCKBaseConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initilzer];
}

- (void)initilzer {
    self.shouldLoadMoreMessagesScrollToTop = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // KVO注册监听
    [self addObserver:self forKeyPath:@"loadingMoreMessage" options:NSKeyValueObservingOptionNew context:LCCKBaseConversationViewControllerRefreshContext];
    
    [LCCKCellRegisterController registerLCCKChatMessageCellClassForTableView:self.tableView];
    self.tableView.frame = ({
        CGRect frame = self.tableView.frame;
        frame.size.height = self.view.frame.size.height - kLCCKChatBarMinHeight;
        frame;
    });
    self.tableView.mj_header = [LCCKConversationRefreshHeader headerWithRefreshingBlock:^{
        if (self.shouldLoadMoreMessagesScrollToTop && !self.loadingMoreMessage) {
            // 进入刷新状态后会自动调用这个block
            [self loadMoreMessagesScrollTotop];
        } else {
            [self.tableView.mj_header endRefreshing];
        }
    }];
}

- (void)setShouldLoadMoreMessagesScrollToTop:(BOOL)shouldLoadMoreMessagesScrollToTop {
    _shouldLoadMoreMessagesScrollToTop = shouldLoadMoreMessagesScrollToTop;
    if (!_shouldLoadMoreMessagesScrollToTop) {
        self.tableView.mj_header = nil;
    }
}

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != LCCKBaseConversationViewControllerRefreshContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCCKBaseConversationViewControllerRefreshContext) {
        //if ([keyPath isEqualToString:@"loadingMoreMessage"]) {
        id newKey = change[NSKeyValueChangeNewKey];
        BOOL boolValue = [newKey boolValue];
        if (!boolValue) {
            [self.tableView.mj_header endRefreshing];
        }
    }
}

- (void)dealloc {
    // KVO反注册
    [self removeObserver:self forKeyPath:@"loadingMoreMessage"];
}

- (void)loadMoreMessagesScrollTotop {
    // This enforces implementing this method in subclasses
    [self doesNotRecognizeSelector:_cmd];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (![self shouldAllowScroll]) {
        return;
    }
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
    }
}

#pragma mark - Getters

- (LCCKChatBar *)chatBar {
    if (!_chatBar) {
        LCCKChatBar *chatBar = [[LCCKChatBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - kLCCKChatBarMinHeight - (self.navigationController.navigationBar.isTranslucent ? 0 : 64), self.view.frame.size.width, kLCCKChatBarMinHeight)];
        [chatBar setSuperViewHeight:[UIScreen mainScreen].bounds.size.height - (self.navigationController.navigationBar.isTranslucent ? 0 : 64)];
#ifdef CYLDebugging
        chatBar.backgroundColor = [UIColor redColor];
#else
#endif
        [self.view addSubview:(_chatBar = chatBar)];
        [self.view bringSubviewToFront:_chatBar];
    }
    return _chatBar;
}

#pragma mark - Scroll Message TableView Helper Method

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = [self tableViewInsetsWithBottomValue:bottom];
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets.bottom = bottom;
    return insets;
}

#pragma mark - Previte Method

- (BOOL)shouldAllowScroll {
    if (self.isUserScrolling) {
        return NO;
    }
    return YES;
}

@end
