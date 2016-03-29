//
//  LCIMBaseTableViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//


#import "LCIMBaseTableViewController.h"
#import "LCIMStatusView.h"
#import "LCIMConstants.h"
#import "LCIMSessionService.h"

@interface LCIMBaseTableViewController ()

@property (nonatomic, strong) LCIMStatusView *clientStatusView;

@end

@implementation LCIMBaseTableViewController

#pragma mark - Publish Method

- (void)configuraSectionIndexBackgroundColorWithTableView:(UITableView *)tableView {
    if ([tableView respondsToSelector:@selector(setSectionIndexBackgroundColor:)]) {
        tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    }
}

- (void)loadDataSource {
    // subClasse
}

#pragma mark - Propertys

- (UITableView *)tableView {
    if (!_tableView) {
        CGRect tableViewFrame = self.view.bounds;
        UITableView *tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:self.tableViewStyle];;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.backgroundColor = self.view.backgroundColor;
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        if (self.tableViewStyle == UITableViewStyleGrouped) {
            UIView *backgroundView = [[UIView alloc] initWithFrame:tableView.bounds];
            backgroundView.backgroundColor = tableView.backgroundColor;
            tableView.backgroundView = backgroundView;
        }
        tableView.delegate = self;
        tableView.dataSource = self;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusView) name:LCIMNotificationConnectivityUpdated object:nil];
    [self updateStatusView];
    // Do any additional setup after loading the view.
}

- (void)dealloc {
    self.dataSource = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
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

- (LCIMStatusView *)clientStatusView {
    if (_clientStatusView == nil) {
        _clientStatusView = [[LCIMStatusView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, LCIMStatusViewHight)];
    }
    return _clientStatusView;
}

- (void)updateStatusView {
    // This enforces implementing this method in subclasses
    [self doesNotRecognizeSelector:_cmd];
}

@end
