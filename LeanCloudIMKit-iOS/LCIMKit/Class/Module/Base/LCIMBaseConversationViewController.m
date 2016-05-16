//
//  LCIMBaseConversationViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//
#define LCIMDebugging 1
#import "LCIMBaseConversationViewController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMCellRegisterController.h"
#import "LCIMChatBar.h"
#import "MJRefresh.h"
#import "LCIMConversationRefreshHeader.h"
static void * const LCIMBaseConversationViewControllerRefreshContext = (void*)&LCIMBaseConversationViewControllerRefreshContext;

@interface LCIMBaseConversationViewController ()
@end

@implementation LCIMBaseConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initilzer];
}

- (void)initilzer {
    self.shouldLoadMoreMessagesScrollToTop = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // KVO注册监听
    [self addObserver:self forKeyPath:@"loadingMoreMessage" options:NSKeyValueObservingOptionNew context:LCIMBaseConversationViewControllerRefreshContext];

    [LCIMCellRegisterController registerLCIMChatMessageCellClassForTableView:self.tableView];
    self.tableView.frame = ({
        CGRect frame = self.tableView.frame;
        frame.size.height = self.view.frame.size.height - kLCIMChatBarMinHeight;
        frame;
    });
    self.tableView.mj_header = [LCIMConversationRefreshHeader headerWithRefreshingBlock:^{
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
    if(context != LCIMBaseConversationViewControllerRefreshContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCIMBaseConversationViewControllerRefreshContext) {
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
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    
    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                                     atScrollPosition:UITableViewScrollPositionBottom
                                             animated:animated];
    }
}

#pragma mark - Getters

- (LCIMChatBar *)chatBar {
    if (!_chatBar) {
        LCIMChatBar *chatBar = [[LCIMChatBar alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - kLCIMChatBarMinHeight - (self.navigationController.navigationBar.isTranslucent ? 0 : 64), self.view.frame.size.width, kLCIMChatBarMinHeight)];
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

@end
