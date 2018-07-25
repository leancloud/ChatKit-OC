//
//  LCCKGroupConversationMemberInfoViewController.m
//  ChatKit-OC
//
//  Created by ZapCannon87 on 2018/7/24.
//  Copyright © 2018 ElonChan. All rights reserved.
//

#import "LCCKGroupConversationMemberInfoViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LCCKGroupConversationMemberInfoViewController ()

@property (nonatomic, strong) NSArray<NSString *> *members;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AVIMConversationMemberInfo *> *memberInfos;

@end

@implementation LCCKGroupConversationMemberInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"群成员信息";
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    
    self.members = self.conversation.members ?: @[];
    self.memberInfos = [NSMutableDictionary dictionary];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
    [self.conversation getAllMemberInfoWithCallback:^(NSArray<AVIMConversationMemberInfo *> * _Nullable memberInfos, NSError * _Nullable error) {
        [hud hide:true];
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"error" message:[NSString stringWithFormat:@"%@", error.description] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:true completion:nil];
        } else {
            NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
            for (AVIMConversationMemberInfo *memberInfo in memberInfos) {
                NSString *memberId = memberInfo.memberId;
                if (memberId) {
                    mutableDic[memberId] = memberInfo;
                }
            }
            self.memberInfos = mutableDic;
            [self.tableView reloadData];
        }
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSString *memberId = self.members[indexPath.row];
    cell.textLabel.text = memberId;
    AVIMConversationMemberInfo *memberInfo = self.memberInfos[memberId];
    if (memberInfo) {
        switch (memberInfo.role) {
            case AVIMConversationMemberRoleOwner:
                cell.detailTextLabel.text = @"Owner";
                break;
            case AVIMConversationMemberRoleManager:
                cell.detailTextLabel.text = @"Manager";
                break;
            case AVIMConversationMemberRoleMember:
                cell.detailTextLabel.text = @"Member";
                break;
            default:
                cell.detailTextLabel.text = @"Member";
                break;
        }
    } else {
        cell.detailTextLabel.text = @"Member";
    }
    return cell;
}

@end
