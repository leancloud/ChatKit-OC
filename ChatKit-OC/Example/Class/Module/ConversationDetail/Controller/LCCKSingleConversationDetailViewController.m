//
//  LCCKSingleConversationDetailViewController.m
//  ChatKit-OC
//
//  Created by 陈宜龙 on 12/8/16.
//  Copyright © 2016 ElonChan. All rights reserved.
//

#import "LCCKSingleConversationDetailViewController.h"
#import "LCCKChatDetailHelper.h"
#import "LCCKUserGroupCell.h"
#import "LCCKUser.h"
#import "CYLTabBarController.h"
#import "LCCKContactManager.h"
#import "NSObject+LCCKHUD.h"

@interface LCCKSingleConversationDetailViewController ()<LCCKUserGroupCellDelegate>

@property (nonatomic, strong) LCCKChatDetailHelper *helper;
@property (nonatomic, strong) LCCKUser *user;

@end

@implementation LCCKSingleConversationDetailViewController
@synthesize data = _data;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"聊天详情"];
    
    self.helper = [[LCCKChatDetailHelper alloc] init];
    
    [self.tableView registerClass:[LCCKUserGroupCell class] forCellReuseIdentifier:@"LCCKUserGroupCell"];
}

- (LCCKUser *)user {
    if (_user) {
        return _user;
    }
    _user = [[LCChatKit sharedInstance] getCachedProfilesIfExists:@[self.conversation.lcck_peerId] error:nil][0];
    return _user;
}

/**
 *  lazy load data
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)data {
    if (_data == nil) {
        _data = [self.helper chatDetailDataBySingleInfo:self.conversation];
    }
    return _data;
}

#pragma mark - Delegate -
//MARK: UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        LCCKUserGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([LCCKUserGroupCell class])];
        [cell setUsers:[NSMutableArray arrayWithArray:@[self.user]]];
        [cell setDelegate:self];
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

//MARK: UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LCCKSettingItem *item = [self.data[indexPath.section] objectAtIndex:indexPath.row];
    
    if ([item.title isEqualToString:@"聊天文件"]) {
        //        LCCKChatFileViewController *chatFileVC = [[LCCKChatFileViewController alloc] init];
        //        [chatFileVC setPartnerID:self.user.userID];
        //        [self setHidesBottomBarWhenPushed:YES];
        //        [self.navigationController pushViewController:chatFileVC animated:YES];
    }
    else if ([item.title isEqualToString:@"设置当前聊天背景"]) {
        [self presentViewController:self.pickerController animated:YES completion:nil];
        
        //        LCCKChatBackgroundSettingViewController *chatBGSettingVC = [[LCCKChatBackgroundSettingViewController alloc] init];
        //        [chatBGSettingVC setPartnerID:self.user.userID];
        //        [self setHidesBottomBarWhenPushed:YES];
        //        [self.navigationController pushViewController:chatBGSettingVC animated:YES];
    }
    else if ([item.title isEqualToString:@"清空聊天记录"]) {
        //        LCCKActionSheet *actionSheet = [[LCCKActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"清空聊天记录" otherButtonTitles: nil];
        //        actionSheet.tag = TAG_EMPTY_CHAT_REC;
        //        [actionSheet show];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)settingSwitchCellForItem:(LCCKSettingItem *)settingItem didChangeStatus:(BOOL)on completionHandler:(LCCKSettingSwitchCellCompletionhandler)completionHandler {
    if ([settingItem.title isEqualToString:@"消息免打扰"]) {
        [[self class] lcck_showHUD];
        __weak __typeof(self) weakSelf = self;
        [self.conversation lcck_setConversationWithMute:on callback:^(BOOL succeeded, NSError *error) {
            completionHandler(succeeded, error);
            [[weakSelf class] lcck_hideHUD];
            if (succeeded) {
                [[LCCKConversationService sharedInstance] removeCacheForConversationId:weakSelf.conversation.conversationId];
                [[weakSelf class] lcck_showSuccess:on ? @"已设为静音" : @"已设为提醒"];
            } else {
                [[weakSelf class] lcck_showSuccess:@"设置失败"];
            }
        }];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Switch事件未被子类处理" message:[NSString stringWithFormat:@"Title: %@\nStatus: %@", settingItem.title, (on ? @"on" : @"off")] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSUInteger count = self.user ? 1 : 0;
        return ((count + 1) / 4 + ((((count + 1) % 4) == 0) ? 0 : 1)) * 90 + 15;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

//MARK: LCCKActionSheetDelegate
//- (void)actionSheet:(LCCKActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (actionSheet.tag == TAG_EMPTY_CHAT_REC) {
//        if (buttonIndex == 0) {
//            BOOL ok = [[LCCKMessageManager sharedInstance] deleteMessagesByPartnerID:self.user.userID];
//            if (!ok) {
//                [UIAlertView bk_alertViewWithTitle:@"错误" message:@"清空聊天记录失败"];
//            }
//            else {
//                [[LCCKChatViewController sharedChatVC] resetChatVC];
//            }
//        }
//    }
//}

#pragma mark -
#pragma mark - LCCKUserGroupCellDelegate Method

- (void)userGroupCellDidSelectUser:(LCCKUser *)user {
    NSString *peerId = user.clientId;
    LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithPeerId:peerId];
    [self cyl_pushOrPopToViewController:conversationViewController animated:YES callback:^(NSArray<__kindof LCCKConversationViewController *> *viewControllers, CYLPushOrPopCompletionHandler completionHandler) {
        __block LCCKConversationViewController *viewControllerPopTo = nil;
        __block BOOL shouldPop = NO;
        [viewControllers enumerateObjectsUsingBlock:^(__kindof LCCKConversationViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.peerId isEqualToString:peerId]) {
                viewControllerPopTo = obj;
                shouldPop = YES;
                *stop = YES;
                return;
            }
        }];
        completionHandler(shouldPop, viewControllerPopTo, YES, 0);
    }];
}

- (void)userGroupCellAddUserButtonDownWithOperationType:(LCCKConversationOperationType)operationType {
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    switch (operationType) {
        case LCCKConversationOperationTypeNone:
            break;
        case LCCKConversationOperationTypeAdd: {
            NSArray *allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
            [self presentSelectMemberViewControllerMemberIds:allPersonIds excludedUserIds:self.conversation.members callback:^(NSArray *peerIds, NSError *error) {
                NSMutableArray *mutableArray = @[currentClientID, self.user.clientId].mutableCopy;;
                [mutableArray addObjectsFromArray:peerIds];
                NSArray *members = [mutableArray copy];
                [[LCChatKit sharedInstance] createConversationWithMembers:members type:LCCKConversationTypeGroup unique:YES callback:^(AVIMConversation * _Nullable conversation, NSError * _Nullable error) {
                    [[self class] lcck_hideHUD];
                    if (conversation) {
                        [[self class] lcck_showSuccess:@"创建对话成功"];
                        [self cyl_popSelectTabBarChildViewControllerAtIndex:0 completion:^(__kindof UIViewController *selectedTabBarChildViewController) {
                            LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversation.conversationId];
                            [selectedTabBarChildViewController.navigationController pushViewController:conversationViewController animated:YES];
                        }];
                    } else {
                        [[self class] lcck_showError:@"创建对话失败"];
                    }
                }];
            }];
        }
            break;
        case LCCKConversationOperationTypeRemove:
            break;
    }
}



@end
