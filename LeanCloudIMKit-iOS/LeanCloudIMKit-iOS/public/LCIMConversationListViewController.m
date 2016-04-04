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
#import "MJRefresh.h"
#import "LCIMConversationService.h"
#import "LCIMConversationListViewModel.h"

@interface LCIMConversationListViewController ()

@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, copy) LCIMConversationListViewModel *conversationListViewModel;

@end

@implementation LCIMConversationListViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"消息";
    self.tableView.delegate = self.conversationListViewModel;
    self.tableView.dataSource = self.conversationListViewModel;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        // 进入刷新状态后会自动调用这个block
        [self.conversationListViewModel refresh];
    }];
    [self.tableView.mj_header beginRefreshing];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
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
 *  lazy load conversationListViewModel
 *
 *  @return LCIMconversationListViewModel
 */
- (LCIMConversationListViewModel *)conversationListViewModel {
    if (_conversationListViewModel == nil) {
        LCIMConversationListViewModel *conversationListViewModel = [[LCIMConversationListViewModel alloc] initWithConversationListViewController:self];
        _conversationListViewModel = conversationListViewModel;
    }
    return _conversationListViewModel;
}

- (void)updateStatusView {
    BOOL isConnected = [LCIMSessionService sharedInstance].connect;
    if (isConnected) {
        self.tableView.tableHeaderView = nil ;
    } else {
        self.tableView.tableHeaderView = (UIView *)self.clientStatusView;
   }
}

- (void)refresh {
    [self.conversationListViewModel refresh];
}

@end
