//
//  LCCKBaseTableViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/9.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//


#import "LCCKBaseTableViewController.h"
#import "LCCKStatusView.h"
#import "LCCKConstants.h"
#import "LCCKSessionService.h"
#import "LCChatKit.h"

@interface LCCKBaseTableViewController () <LCCKStatusViewDelegate>

@property (nonatomic, strong) LCCKStatusView *clientStatusView;

@end

@implementation LCCKBaseTableViewController

#pragma mark - Publish Method

- (void)configuraSectionIndexBackgroundColorWithTableView:(UITableView *)tableView {
    if ([tableView respondsToSelector:@selector(setSectionIndexBackgroundColor:)]) {
        tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    }
}

- (void)loadDataSource {
    // subClass
}

#pragma mark - Propertys

- (UITableView *)tableView {
    if (!_tableView) {
        CGRect tableViewFrame = self.view.bounds;
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:self.tableViewStyle];
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.backgroundColor = [UIColor clearColor];
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        if (self.tableViewStyle == UITableViewStyleGrouped) {
            UIView *backgroundView = [[UIView alloc] initWithFrame:tableView.bounds];
            backgroundView.backgroundColor = tableView.backgroundColor;
            tableView.backgroundView = backgroundView;
        }
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.tableFooterView = [[UIView alloc] init];
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        [self.view addSubview:_tableView = tableView];
    }
    return _tableView;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return _dataSource;
}

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    //view在导航栏下方
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusView) name:LCCKNotificationConnectivityUpdated object:nil];
    if (self.viewControllerStyle == LCCKViewControllerStylePresenting) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismissViewController:)];
    }
    self.checkSessionStatus = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)dismissViewController:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)dealloc {
//    self.dataSource = nil;
//    self.tableView.delegate = nil;
//    self.tableView.dataSource = nil;
//    self.tableView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // in subClass
    return nil;
}

#pragma mark - connect status view

- (LCCKStatusView *)clientStatusView {
    if (_clientStatusView == nil) {
        _clientStatusView = [[LCCKStatusView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, LCCKStatusViewHight)];
        _clientStatusView.delegate = self;
    }
    return _clientStatusView;
}

- (void)updateStatusView {}

- (void)statusViewClicked:(id)sender {
    [[LCCKSessionService sharedInstance] reconnectForViewController:self callback:nil];
}

- (void)applicationDidBecomeActive:(NSNotification*)note {
    self.checkSessionStatus = YES;
}

- (void)applicationWillResignActive:(NSNotification*)note {
    self.checkSessionStatus = NO;
}

@end
