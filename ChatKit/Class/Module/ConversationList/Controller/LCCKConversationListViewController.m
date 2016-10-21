//
//  LCCKConversationListViewController.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKConversationListViewController.h"
#import "LCCKConstants.h"
#import "LCCKSessionService.h"
#import "LCCKConversationService.h"
#import "LCCKConversationListViewModel.h"

#if __has_include(<MJRefresh/MJRefresh.h>)
    #import <MJRefresh/MJRefresh.h>
#else
    #import "MJRefresh.h"
#endif

@interface LCCKConversationListViewController ()

@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, copy) LCCKConversationListViewModel *conversationListViewModel;

@end

@implementation LCCKConversationListViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    BOOL clientStatusOpened = [LCCKSessionService sharedInstance].client.status == AVIMClientStatusOpened;
    //NSAssert([LCCKSessionService sharedInstance].client.status == AVIMClientStatusOpened, @"client not opened");
    if (!clientStatusOpened) {
        [[LCCKSessionService sharedInstance] reconnectForViewController:self callback:nil];
    }
    self.navigationItem.title = @"消息";
    self.tableView.delegate = self.conversationListViewModel;
    self.tableView.dataSource = self.conversationListViewModel;
    __weak __typeof(self) weakSelf = self;
    self.tableView.mj_header = ({
        MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            // 进入刷新状态后会自动调用这个 block
            [weakSelf.conversationListViewModel refresh];
            // 设置颜色
        }];
        header.stateLabel.textColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"TableView-PullRefresh-TextColor"];
        header.lastUpdatedTimeLabel.textColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"TableView-PullRefresh-TextColor"];
        header.backgroundColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"TableView-PullRefresh-BackgroundColor"];
        header;
    });
    self.tableView.backgroundColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"TableView-BackgroundColor"];
    [self.tableView.mj_header beginRefreshing];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock(self);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(self, animated);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(self, animated);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(self, animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(self, animated);
}

- (void)dealloc {
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock(self);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock(self);
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
 *  @return LCCKconversationListViewModel
 */
- (LCCKConversationListViewModel *)conversationListViewModel {
    if (_conversationListViewModel == nil) {
        LCCKConversationListViewModel *conversationListViewModel = [[LCCKConversationListViewModel alloc] initWithConversationListViewController:self];
        _conversationListViewModel = conversationListViewModel;
    }
    return _conversationListViewModel;
}

- (void)updateStatusView {
    if (!self.shouldCheckSessionStatus) {
        return;
    }
    BOOL isConnected = [LCCKSessionService sharedInstance].connect;
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
