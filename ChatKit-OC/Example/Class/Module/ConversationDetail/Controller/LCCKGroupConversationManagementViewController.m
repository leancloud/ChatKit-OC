//
//  LCCKGroupConversationManagementViewController.m
//  ChatKit-OC
//
//  Created by ZapCannon87 on 2018/7/24.
//  Copyright © 2018 ElonChan. All rights reserved.
//

#import "LCCKGroupConversationManagementViewController.h"
#import "LCCKGroupConversationMemberInfoViewController.h"

@interface LCCKGroupConversationManagementViewController ()

@end

@implementation LCCKGroupConversationManagementViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"群管理";
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (indexPath.row == 0) {
        cell.textLabel.text = @"群成员信息";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if (indexPath.row == 0) {
        LCCKGroupConversationMemberInfoViewController *vc = [[LCCKGroupConversationMemberInfoViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.conversation = self.conversation;
        [self.navigationController pushViewController:vc animated:true];
    }
}

@end
