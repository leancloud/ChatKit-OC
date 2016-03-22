//
//  LCIMConversationListViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMConversationListViewController.h"
#import "LCIMConstants.h"
#import "LCIMSessionService.h"
#import "LCIMStatusView.h"
#import "MJRefresh.h"
#import "LCIMConversationService.h"
#import "LCIMConversatonListViewModel.h"

@interface LCIMConversationListViewController ()

@property (nonatomic, strong) LCIMStatusView *clientStatusView;
@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, copy) LCIMConversationsListDidSelectItemBlock conversationsListDidSelectItemBlock;
@property (nonatomic, copy) LCIMConversationsListDidDeleteItemBlock didDeleteItemBlock;
@property (nonatomic, copy) LCIMMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock;
@property (nonatomic, copy) LCIMPrepareConversationsWhenLoadBlock prepareConversationsWhenLoadBlock;
@property (nonatomic, copy) LCIMConversatonListViewModel *conversatonListViewModel;

@end

@implementation LCIMConversationListViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"消息";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusView) name:LCIMNotificationConnectivityUpdated object:nil];
    [self updateStatusView];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        // 进入刷新状态后会自动调用这个block
        [self.conversatonListViewModel refresh];
    }];
    [self.tableView.mj_header beginRefreshing];
    self.tableView.delegate = self.conversatonListViewModel;
    self.tableView.dataSource = self.conversatonListViewModel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - connect status view

- (LCIMStatusView *)clientStatusView {
    if (_clientStatusView == nil) {
        _clientStatusView = [[LCIMStatusView alloc] initWithFrame:CGRectMake(0, 64, self.tableView.frame.size.width, LCIMStatusViewHight)];
        _clientStatusView.hidden = YES;
    }
    return _clientStatusView;
}

- (void)updateStatusView {
    if ([LCIMSessionService sharedInstance].connect) {
        self.clientStatusView.hidden = YES;
    } else {
        self.clientStatusView.hidden = NO;
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark - LazyLoad Method

/**
 *  lazy load conversations
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)conversations
{
    if (_conversations == nil) {
        _conversations = [[NSMutableArray alloc] init];
    }
    return _conversations;
}

/**
 *  lazy load conversatonListViewModel
 *
 *  @return LCIMConversatonListViewModel
 */
- (LCIMConversatonListViewModel *)conversatonListViewModel {
    if (_conversatonListViewModel == nil) {
        LCIMConversatonListViewModel *conversatonListViewModel = [[LCIMConversatonListViewModel alloc] initWithConversationListViewController:self];
        _conversatonListViewModel = conversatonListViewModel;
    }
    return _conversatonListViewModel;
}

#pragma mark -
#pragma mark - Setter Method

- (void)setDidSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)didSelectItemBlock {
    _didDeleteItemBlock = didSelectItemBlock;
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCIMMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    _markBadgeWithTotalUnreadCountBlock = markBadgeWithTotalUnreadCountBlock;
}

- (void)setPrepareConversationsWhenLoadBlock:(LCIMPrepareConversationsWhenLoadBlock)prepareConversationsWhenLoadBlock {
    _prepareConversationsWhenLoadBlock = prepareConversationsWhenLoadBlock;
}

- (void)setDidDeleteItemBlock:(LCIMConversationsListDidSelectItemBlock)didDeleteItemBlock {
    _didDeleteItemBlock = didDeleteItemBlock;
}

@end
