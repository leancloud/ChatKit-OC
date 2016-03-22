//
//  LCIMBaseConversationViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 EloncChan. All rights reserved.
//
#define LCIMDebugging 1
#import "LCIMBaseConversationViewController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMCellRegisterController.h"
#import "LCIMChatBar.h"
// Categorys
#import "UIScrollView+XHkeyboardControl.h"
#import "MJRefresh.h"
#import "LCIMConversationRefreshHeader.h"

@interface LCIMBaseConversationViewController ()
//@property (nonatomic, strong) UIActivityIndicatorView *loadMoreActivityIndicatorView;
//@property (nonatomic, strong) UIView *headerContainerView;

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
        }
    }];
//    [self setTableViewInsetsWithBottomValue:kLCIMChatBarMinHeight];
}

//- (UIView *)headerContainerView {
//    if (!_headerContainerView) {
//        _headerContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
//        _headerContainerView.backgroundColor = self.tableView.backgroundColor;
//#ifdef LCIMDebugging
//        _headerContainerView.backgroundColor = [UIColor redColor];
//#endif
//        [_headerContainerView addSubview:self.loadMoreActivityIndicatorView];
//        self.loadMoreActivityIndicatorView.center = CGPointMake(CGRectGetWidth(_headerContainerView.bounds) / 2.0, CGRectGetHeight(_headerContainerView.bounds) / 2.0);
//    }
//    return _headerContainerView;
//}

- (void)setLoadingMoreMessage:(BOOL)loadingMoreMessage {
    _loadingMoreMessage = loadingMoreMessage;
//    if (loadingMoreMessage) {
//        dispatch_async(dispatch_get_main_queue(),^{
//            if (!self.loadMoreActivityIndicatorView.isAnimating) {
//                [self.loadMoreActivityIndicatorView startAnimating];
//            }
//        });
//    } else {
//        dispatch_async(dispatch_get_main_queue(),^{
//            if (self.loadMoreActivityIndicatorView.isAnimating) {
//                [self.loadMoreActivityIndicatorView stopAnimating];
//            }
//        });
//    }
}

//- (UIActivityIndicatorView *)loadMoreActivityIndicatorView {
//    if (!_loadMoreActivityIndicatorView) {
//        _loadMoreActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//#ifdef LCIMDebugging
//        _loadMoreActivityIndicatorView.backgroundColor = [UIColor blueColor];
//#endif
//    }
//    return _loadMoreActivityIndicatorView;
//}

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
        [_chatBar bringSubviewToFront:self.view];
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
