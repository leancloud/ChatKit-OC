//
//  LCIMBaseTableViewController.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 EloncChan. All rights reserved.
//


#import "LCIMBaseTableViewController.h"

@interface LCIMBaseTableViewController ()

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
        tableViewFrame.size.height -= (self.navigationController.viewControllers.count > 1 ? 0 : (CGRectGetHeight(self.tabBarController.tabBar.bounds)));
        _tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:self.tableViewStyle];
        _tableView.delegate = self;
        _tableView.dataSource = self;
            if (self.tableViewStyle == UITableViewStyleGrouped) {
                UIView *backgroundView = [[UIView alloc] initWithFrame:_tableView.bounds];
                backgroundView.backgroundColor = _tableView.backgroundColor;
                _tableView.backgroundView = backgroundView;
        }
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
    // Do any additional setup after loading the view.
    [self.view addSubview:self.tableView];
}

- (void)dealloc {
    self.dataSource = nil;
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    self.tableView = nil;
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


@end
