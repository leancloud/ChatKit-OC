//
//  LCCKBaseConversationViewController.m
//  LeanCloudIMKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//
//#define LCCKDebugging 1
#import "LCCKBaseConversationViewController.h"
#import "LCCKCellRegisterController.h"
#import "LCCKChatBar.h"
#import "LCCKConversationRefreshHeader.h"

#if __has_include(<CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>)
#import <CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>
#else
#import "CYLDeallocBlockExecutor.h"
#endif

#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
#if __has_include(<MJRefresh/MJRefresh.h>)
    #import <MJRefresh/MJRefresh.h>
#else
    #import "MJRefresh.h"
#endif

static void * const LCCKBaseConversationViewControllerRefreshContext = (void*)&LCCKBaseConversationViewControllerRefreshContext;
static CGFloat const LCCKScrollViewInsetTop = 20.f;

@interface LCCKBaseConversationViewController ()

@end

@implementation LCCKBaseConversationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initilzer];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.left.and.width.equalTo(self.view);
        make.bottom.equalTo(self.chatBar.mas_top);
    }];
    [self.chatBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.bottom.equalTo(self.view);
        make.height.mas_greaterThanOrEqualTo(@(kLCCKChatBarMinHeight));
    }];
}

- (void)initilzer {
    self.shouldLoadMoreMessagesScrollToTop = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // KVO注册监听
    [self addObserver:self forKeyPath:@"loadingMoreMessage" options:NSKeyValueObservingOptionNew context:LCCKBaseConversationViewControllerRefreshContext];
    __unsafe_unretained __typeof(self) weakSelf = self;
    [self cyl_executeAtDealloc:^{
        [weakSelf removeObserver:weakSelf forKeyPath:@"loadingMoreMessage"];
    }];
    [LCCKCellRegisterController registerChatMessageCellClassForTableView:self.tableView];
//    [self setTableViewInsetsWithBottomValue:kLCCKChatBarMinHeight];
    __weak __typeof(self) weakSelf_ = self;
    self.tableView.mj_header = [LCCKConversationRefreshHeader headerWithRefreshingBlock:^{
        if (weakSelf_.shouldLoadMoreMessagesScrollToTop && !weakSelf_.loadingMoreMessage) {
            // 进入刷新状态后会自动调用这个block
            [weakSelf_ loadMoreMessagesScrollTotop];
        } else {
            [weakSelf_.tableView.mj_header endRefreshing];
        }
    }];
}

#pragma mark - Scroll Message TableView Helper Method

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = [self tableViewInsetsWithBottomValue:bottom];
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets.top = LCCKScrollViewInsetTop;
    insets.bottom = bottom;
    return insets;
}

- (void)setShouldLoadMoreMessagesScrollToTop:(BOOL)shouldLoadMoreMessagesScrollToTop {
    _shouldLoadMoreMessagesScrollToTop = shouldLoadMoreMessagesScrollToTop;
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
            if (!_shouldLoadMoreMessagesScrollToTop) {
                self.tableView.mj_header = nil;
            }
        }
    }
}

- (void)loadMoreMessagesScrollTotop {
    // This enforces implementing this method in subclasses
    [self doesNotRecognizeSelector:_cmd];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (!self.allowScrollToBottom) {
        return;
    }
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    if (rows > 0) {
        dispatch_block_t scrollBottomBlock = ^ {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:animated];
        };
        if (animated) {
            //when use `estimatedRowHeight` and `scrollToRowAtIndexPath` at the same time, there are some issue.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                scrollBottomBlock();
            });
        } else {
            scrollBottomBlock();
        }
        
    }
}

#pragma mark - Getters

- (LCCKChatBar *)chatBar {
    if (!_chatBar) {
        LCCKChatBar *chatBar = [[LCCKChatBar alloc] init];
        [self.view addSubview:(_chatBar = chatBar)];
        [self.view bringSubviewToFront:_chatBar];
    }
    return _chatBar;
}

@end
