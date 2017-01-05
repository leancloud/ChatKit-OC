//
//  LCCKGroupConversationDetailViewController.m
//  ChatKit-OC
//
//  Created by 陈宜龙 on 12/8/16.
//  Copyright © 2016 ElonChan. All rights reserved.
//

#import "LCCKGroupConversationDetailViewController.h"
#import "LCCKUserGroupCell.h"
#import "LCCKChatDetailHelper.h"
#import <ChatKit/LCChatKit.h>
#import "LCCKContactManager.h"
#import "LCCKProfileNameEditViewController.h"
#import "CYLTabBarController.h"
#import "LCCKUser.h"

@interface LCCKGroupConversationDetailViewController ()<LCCKUserGroupCellDelegate, LCCKProfileNameEditViewControllerDelegate>

@property (nonatomic, strong) LCCKChatDetailHelper *helper;

@end

@implementation LCCKGroupConversationDetailViewController
@synthesize data = _data;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"聊天详情"];
    
    self.helper = [[LCCKChatDetailHelper alloc] init];
    
    [self.tableView registerClass:[LCCKUserGroupCell class] forCellReuseIdentifier:NSStringFromClass([LCCKUserGroupCell class])];
}

/**
 *  lazy load data
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)data {
    if (_data == nil) {
        _data = [self.helper chatDetailDataByGroupInfo:self.conversation];
    }
    return _data;
}

#pragma mark - Delegate -
//MARK: UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        LCCKUserGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([LCCKUserGroupCell class])];
        NSArray *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:self.conversation.members error:nil];
        [cell setUsers:[users mutableCopy]];
        [cell setDelegate:self];
        [cell.collectionView reloadData];
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

//MARK: UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    LCCKSettingItem *item = [self.data[indexPath.section] objectAtIndex:indexPath.row];
    if ([item.title isEqualToString:@"群聊名称"]) {
        BOOL isCreater = [self.conversation lcck_isCreaterForCurrentUser];
        BOOL tooManyMembers = self.conversation.members.count > 5;
        if (tooManyMembers && !isCreater) {
            NSString *creatorNickname = nil;
            [[LCChatKit sharedInstance] getCachedProfileIfExists:self.conversation.creator name:&creatorNickname avatarURL:nil error:nil];
            NSString *title = [NSString stringWithFormat:@"当前群聊人数较多，只有群主%@才能修改群名称", creatorNickname ?: self.conversation.creator];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:title delegate:self cancelButtonTitle:@"我知道了" otherButtonTitles:nil];
            [alert show];
            return;
        }
        LCCKProfileNameEditViewController *profileNameEditViewController = [[LCCKProfileNameEditViewController alloc] init];
        profileNameEditViewController.title = @"群聊名称";
        profileNameEditViewController.delegate = self;
        profileNameEditViewController.placeholderName = self.conversation.name;

        [self.navigationController pushViewController:profileNameEditViewController animated:YES];
    } else if ([item.title isEqualToString:@"群二维码"]) {
//        LCCKGroupQRCodeViewController *gorupQRCodeVC = [[LCCKGroupQRCodeViewController alloc] init];
//        [gorupQRCodeVC setGroup:self.conversation];
//        [self setHidesBottomBarWhenPushed:YES];
//        [self.navigationController pushViewController:gorupQRCodeVC animated:YES];
    }
    else if ([item.title isEqualToString:@"设置当前聊天背景"]) {
        [self presentViewController:self.pickerController animated:YES completion:nil];
//        LCCKChatBackgroundSettingViewController *chatBGSettingVC = [[LCCKChatBackgroundSettingViewController alloc] init];
//        [chatBGSettingVC setPartnerID:self.conversation.groupID];
//        [self setHidesBottomBarWhenPushed:YES];
//        [self.navigationController pushViewController:chatBGSettingVC animated:YES];
    }
    else if ([item.title isEqualToString:@"聊天文件"]) {
//        LCCKChatFileViewController *chatFileVC = [[LCCKChatFileViewController alloc] init];
//        [chatFileVC setPartnerID:self.conversation.groupID];
//        [self setHidesBottomBarWhenPushed:YES];
//        [self.navigationController pushViewController:chatFileVC animated:YES];
    }
    else if ([item.title isEqualToString:@"清空聊天记录"]) {
//        LCCKActionSheet *actionSheet = [[LCCKActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"清空聊天记录" otherButtonTitles: nil];
//        actionSheet.tag = TAG_EMPTY_CHAT_REC;
//        [actionSheet show];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        NSUInteger count = self.conversation.members.count;
        if ([self lcck_isCreatorForCurrentGroupConversaton]) {
            count ++;
        }
        return ((count + 1) / 4 + ((((count + 1) % 4) == 0) ? 0 : 1)) * 90 + 15;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

//MARK: LCCKActionSheetDelegate
//- (void)actionSheet:(LCCKActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (actionSheet.tag == TAG_EMPTY_CHAT_REC) {
//        if (buttonIndex == 0) {
//            BOOL ok = [[LCCKMessageManager sharedInstance] deleteMessagesByPartnerID:self.conversation.groupID];
//            if (!ok) {
//                [UIAlertView bk_alertViewWithTitle:@"错误" message:@"清空讨论组聊天记录失败"];
//            }
//            else {
//                [[LCCKChatViewController sharedChatVC] resetChatVC];
//            }
//        }
//    }
//}

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

- (void)userGroupCellDidSelectUser:(LCCKUser *)user {
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    if ([currentClientID isEqualToString:user.clientId]) {
        return;
    }
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
    switch (operationType) {
        case LCCKConversationOperationTypeNone:
            break;
        case LCCKConversationOperationTypeAdd: {
            NSArray *allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
            [self presentSelectMemberViewControllerMemberIds:allPersonIds excludedUserIds:self.conversation.members callback:^(NSArray *peerIds, NSError *error) {
                __weak __typeof(self) weakSelf = self;
                [self addAndCacheMembersWithClientIds:peerIds callback:^(BOOL succeeded, NSError * _Nullable error) {
                    [[weakSelf class] lcck_hideHUD];
                    if (succeeded) {
                        _data = nil;
                        [[weakSelf class] lcck_showSuccess:@"添加成功"];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                        NSArray *indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
                        [weakSelf.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                    } else {
                        [[weakSelf class] lcck_showError:@"添加失败"];
                    }
                }];
            }];
        }
            break;
        case LCCKConversationOperationTypeRemove: {
            [self presentSelectMemberViewControllerMemberIds:self.conversation.members excludedUserIds:nil callback:^(NSArray *peerIds, NSError *error) {
                [self.conversation removeMembersWithClientIds:peerIds callback:^(BOOL succeeded, NSError * _Nullable error) {
                    [[self class] lcck_hideHUD];
                    if (succeeded) {
                        [[self class] lcck_showSuccess:@"移除成功"];
                        self.data = nil;
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                        NSArray *indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
                        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                    } else {
                        [[self class] lcck_showError:@"移除失败"];
                    }
                }];
            }];
        }
            break;
    }
}

- (void)addAndCacheMembersWithClientIds:(NSArray *)clientIds callback:(LCCKBooleanResultBlock)callback {
    void(^addAndCacheCallback)(BOOL succeeded, NSError *error) = ^(BOOL succeeded, NSError *error) {
        !callback ?: callback(succeeded, error);
    };
    [self.conversation addMembersWithClientIds:clientIds callback:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            [[LCCKUserSystemService sharedInstance] cacheUsersWithIds:[NSSet setWithArray:clientIds] callback:^(BOOL succeeded, NSError *error) {
                addAndCacheCallback(succeeded, error);
            }];
        } else {
            addAndCacheCallback(succeeded, error);
        }
    }];
}

- (void)profileNameDidChanged:(NSString *)name {
    [[self class] lcck_showHUD];
    //FIXME:
//    [self.conversation setObject:name forKey:@"name"];
//    [self.conversation updateWithCallback:^(BOOL succeeded, NSError * _Nullable error) {
//        [[self class] lcck_hideHUD];
//        if (succeeded) {
//            [[self class] lcck_showSuccess:@"修改成功"];
//            self.data = nil;
//            [self.tableView reloadData];
//            [[LCCKConversationService sharedInstance] removeCacheForConversationId:self.conversation.conversationId];
//        } else {
//            [[self class] lcck_showError:@"修改失败"];
//        }
//    }];
    
}


@end
