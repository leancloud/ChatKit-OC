//
//  LCCKGroupConversationMemberInfoViewController.m
//  ChatKit-OC
//
//  Created by ZapCannon87 on 2018/7/24.
//  Copyright © 2018 ElonChan. All rights reserved.
//

#import "LCCKGroupConversationMemberInfoViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LCCKGroupConversationMemberInfoModel : NSObject

@property (nonatomic, strong) NSString *memberId;
@property (nonatomic, assign) AVIMConversationMemberRole role;

@end

@implementation LCCKGroupConversationMemberInfoModel

@end

@interface LCCKGroupConversationMemberInfoViewController ()

@property (nonatomic, strong) NSArray<NSString *> *members;
@property (nonatomic, strong) NSMutableDictionary<NSString *, LCCKGroupConversationMemberInfoModel *> *memberInfos;

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
    [self.conversation getAllMemberInfoWithIgnoringCache:true callback:^(NSArray<AVIMConversationMemberInfo *> * _Nullable memberInfos, NSError * _Nullable error) {
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
                    LCCKGroupConversationMemberInfoModel *model = [LCCKGroupConversationMemberInfoModel new];
                    model.memberId = memberId;
                    model.role = memberInfo.role;
                    mutableDic[memberId] = model;
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
    if (cell.detailTextLabel == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    NSString *memberId = self.members[indexPath.row];
    cell.textLabel.text = memberId;
    LCCKGroupConversationMemberInfoModel *memberInfo = self.memberInfos[memberId];
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
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    NSString *memberId = self.members[indexPath.row];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Role" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil]];
    void(^updateRole)(AVIMConversationMemberRole) = ^(AVIMConversationMemberRole role) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:true];
        [self.conversation updateMemberRoleWithMemberId:memberId role:role callback:^(BOOL succeeded, NSError * _Nullable error) {
            [hud hide:true];
            if (error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"error" message:[NSString stringWithFormat:@"%@", error.description] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:true completion:nil];
            } else {
                LCCKGroupConversationMemberInfoModel *model = self.memberInfos[memberId];
                if (model) {
                    model.role = role;
                } else {
                    model = [LCCKGroupConversationMemberInfoModel new];
                    model.memberId = memberId;
                    model.role = role;
                    self.memberInfos[memberId] = model;
                }
                [self.tableView reloadData];
            }
        }];
    };
    [alert addAction:[UIAlertAction actionWithTitle:@"Member" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        updateRole(AVIMConversationMemberRoleMember);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Manager" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        updateRole(AVIMConversationMemberRoleManager);
    }]];
    [self presentViewController:alert animated:true completion:nil];
}

@end
