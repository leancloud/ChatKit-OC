//
//  LCCKConversationListViewModel.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKConversationListViewModel.h"
#import "LCCKConversationListCell.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKUserDelegate.h"
#import "LCCKUserSystemService.h"
#import "LCCKConversationListViewController.h"
#import "LCCKConstants.h"
#import "AVIMConversation+LCCKExtension.h"
#import "LCCKLastMessageTypeManager.h"
#import "NSDate+LCCKDateTools.h"
#import "LCCKConversationListService.h"
#import "UIImage+LCCKExtension.h"

#if __has_include(<MJRefresh/MJRefresh.h>)
    #import <MJRefresh/MJRefresh.h>
#else
    #import "MJRefresh.h"
#endif

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
    #import <SDWebImage/UIImageView+WebCache.h>
#else
    #import "UIImageView+WebCache.h"
#endif
#import "LCCKDeallocBlockExecutor.h"



@interface LCCKConversationListViewModel ()

@property (nonatomic, weak) LCCKConversationListViewController *conversationListViewController;
@property (nonatomic, assign, getter=isFreshing) BOOL freshing;

@end

@implementation LCCKConversationListViewModel

#pragma mark -
#pragma mark - LifeCycle Method

- (instancetype)initWithConversationListViewController:(LCCKConversationListViewController *)conversationListViewController {
    self = [super init];
    if (!self) {
        return nil;
    }
    // 当在其它 Tab 的时候，收到消息, badge 增加，所以需要一直监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:LCCKNotificationMessageReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:LCCKNotificationUnreadsUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:LCCKNotificationConversationListDataSourceUpdated object:nil];
    __unsafe_unretained typeof(self) weakSelf = self;
    [self lcck_executeAtDealloc:^{
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
    }];
    _conversationListViewController = conversationListViewController;
    return self;
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
    
    LCCKCellForRowBlock cellForRowBlock = [[LCCKConversationListService sharedInstance] cellForRowBlock];
    if (cellForRowBlock) {
        UITableViewCell *customCell = cellForRowBlock(tableView, indexPath, conversation);
        LCCKConfigureCellBlock configureCellBlock = [[LCCKConversationListService sharedInstance] configureCellBlock];
        if (configureCellBlock) {
            configureCellBlock(customCell, tableView, indexPath, conversation);
        }
        return customCell;
    }
    LCCKConversationListCell *cell = [LCCKConversationListCell dequeueOrCreateCellByTableView:tableView];
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    [tableView setSeparatorColor:[[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"TableView-SeparatorColor"]];
    __block NSString *displayName = nil;
    __block NSURL *avatarURL = nil;
    NSString *peerId = nil;
    if (conversation.lcck_type == LCCKConversationTypeSingle) {
        peerId = conversation.lcck_peerId;
    } else {
        peerId = conversation.lcck_lastMessage.clientId;
    }
    if (peerId) {
        [self asyncCacheElseNetLoadCell:cell peerId:peerId name:&displayName avatarURL:&avatarURL];
    }
    if (conversation.lcck_type == LCCKConversationTypeSingle) {
        [cell.avatarImageView sd_setImageWithURL:avatarURL placeholderImage:[self imageInBundleForImageName:@"Placeholder_Avatar" ]];
    } else {
        NSString *conversationGroupAvatarURLKey = [conversation.attributes valueForKey:LCCKConversationGroupAvatarURLKey];
        NSURL *conversationGroupAvatarURL = [NSURL URLWithString:conversationGroupAvatarURLKey];
        [cell.avatarImageView sd_setImageWithURL:conversationGroupAvatarURL placeholderImage:[self imageInBundleForImageName:@"Placeholder_Group" ]];
    }
    
    cell.nameLabel.text = conversation.lcck_displayName;
    if (conversation.lcck_lastMessage) {
        cell.messageTextLabel.attributedText = [LCCKLastMessageTypeManager attributedStringWithMessage:conversation.lcck_lastMessage conversation:conversation userName:displayName];
        cell.timestampLabel.text = [[NSDate dateWithTimeIntervalSince1970:conversation.lcck_lastMessage.sendTimestamp / 1000] lcck_timeAgoSinceNow];
    }
    if (conversation.lcck_unreadCount > 0) {
        if (conversation.muted) {
            cell.litteBadgeView.hidden = NO;
        } else {
            cell.badgeView.badgeText = conversation.lcck_badgeText;
        }
    }
    if (conversation.muted == YES) {
        cell.remindMuteImageView.hidden = NO;
    }
    LCCKConfigureCellBlock configureCellBlock = [[LCCKConversationListService sharedInstance] configureCellBlock];
    if (configureCellBlock) {
        configureCellBlock(cell, tableView, indexPath, conversation);
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKConversationEditActionsBlock conversationEditActionBlock = [[LCCKConversationListService sharedInstance] conversationEditActionBlock];
    AVIMConversation *conversation = nil;
    if ((NSUInteger)indexPath.row < self.dataArray.count) {
        conversation = [self.dataArray objectAtIndex:indexPath.row];
    }
    else {
        return nil;
    }
    NSArray *editActions = [NSArray array];
    if (conversationEditActionBlock) {
        editActions = conversationEditActionBlock(indexPath, [self defaultRightButtons], conversation, self.conversationListViewController);
    } else {
        editActions = [self defaultRightButtons];
    }
    return editActions;
}

- (void)asyncCacheElseNetLoadCell:(LCCKConversationListCell *)cell peerId:(NSString *)peerId name:(NSString **)name avatarURL:(NSURL **)avatarURL {
    NSError *error = nil;
    cell.identifier = peerId;
    [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:peerId name:name avatarURL:avatarURL error:&error];
    if (error) {
//        NSLog(@"%@", error);
    }
    //头像消息一般和昵称消息一同返回，故假设如果服务端返回了昵称，那么如果该用户有头像就一定会返回头像。反之，没返回昵称，一定是还未缓存用户信息。如果你的App中，不是这样的逻辑，可联系维护者将这一逻辑修改得严谨些，邮箱luohanchenyilong@163.com.
    if (!*name) {
        if (peerId != NULL && ![LCCKSettingService sharedInstance].isDisablePreviewUserId) {
            *name = peerId;
        }
        __weak __typeof(self) weakSelf = self;
        __weak __typeof(cell) weakCell = cell;
        [[LCCKUserSystemService sharedInstance] getProfileInBackgroundForUserId:peerId callback:^(id<LCCKUserDelegate> user, NSError *error) {
            BOOL hasData = user.name;
            if (hasData && [weakCell.identifier isEqualToString:user.clientId]) {
                NSIndexPath *indexPath_ = [weakSelf.conversationListViewController.tableView indexPathForCell:weakCell];
                if (!indexPath_) {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(),^{
                    [weakSelf.conversationListViewController.tableView reloadRowsAtIndexPaths:@[indexPath_] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
        }];
    }
}

- (NSArray *)defaultRightButtons {
    UITableViewRowAction *actionItemDelete = [UITableViewRowAction
                                              rowActionWithStyle:UITableViewRowActionStyleNormal
                                              title:LCCKLocalizedStrings(@"Delete")
                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                  AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
                                                  [[LCCKConversationService sharedInstance] deleteRecentConversationWithConversationId:conversation.conversationId];
                                                  [self refresh];
                                                  LCCKDidDeleteConversationsListCellBlock conversationsListDidDeleteItemBlock = [LCCKConversationListService sharedInstance].didDeleteConversationsListCellBlock;
                                                  !conversationsListDidDeleteItemBlock ?: conversationsListDidDeleteItemBlock(indexPath, conversation, self.conversationListViewController);
                                              }];
    actionItemDelete.backgroundColor = [UIColor redColor];
    return @[ actionItemDelete ];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
    [conversation markAsReadInBackground];
//    [self refreshIfNeeded];
    ![LCCKConversationListService sharedInstance].didSelectConversationsListCellBlock ?: [LCCKConversationListService sharedInstance].didSelectConversationsListCellBlock(indexPath, conversation, self.conversationListViewController);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKHeightForRowBlock heightForRowBlock = [[LCCKConversationListService sharedInstance] heightForRowBlock];
    if (heightForRowBlock) {
        AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
        return heightForRowBlock(tableView, indexPath, conversation);
    }
    return LCCKConversationListCellDefaultHeight;
}

#pragma mark - refresh

- (void)setFreshing:(BOOL)freshing {
    _freshing = freshing;
    if (freshing == NO) {
        [self.conversationListViewController.tableView.mj_header endRefreshing];
    }
}

- (void)refresh {
    self.freshing = YES;
    [[LCCKConversationListService sharedInstance] findRecentConversationsWithBlock:^(NSArray *conversations, NSInteger totalUnreadCount, NSError *error) {
        dispatch_block_t finishBlock = ^{
            self.freshing = NO;
            if ([self.conversationListViewController filterAVIMError:error]) {
                self.dataArray = [NSMutableArray arrayWithArray:conversations];
                [self.conversationListViewController.tableView reloadData];
                [self selectConversationIfHasRemoteNotificatoinConvid];
                LCCKMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock = [LCCKConversationListService sharedInstance].markBadgeWithTotalUnreadCountBlock;
                if (markBadgeWithTotalUnreadCountBlock) {
                    [LCCKConversationListService sharedInstance].markBadgeWithTotalUnreadCountBlock(totalUnreadCount, self.conversationListViewController.navigationController);
                    return;
                }
                if (totalUnreadCount > 0) {
                    NSString *badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
                    if (totalUnreadCount > 99) {
                        badgeValue = LCCKBadgeTextForNumberGreaterThanLimit;
                    }
                    [self.conversationListViewController.navigationController tabBarItem].badgeValue = badgeValue;
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUnreadCount];
                } else {
                    [self.conversationListViewController.navigationController tabBarItem].badgeValue = nil;
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                }
            }
        };
        if([LCCKConversationListService sharedInstance].prepareConversationsWhenLoadBlock) {
            [LCCKConversationListService sharedInstance].prepareConversationsWhenLoadBlock(conversations, ^(BOOL succeeded, NSError *error) {
                if ([self.conversationListViewController filterAVIMError:error]) {
                    finishBlock();
                } else {
                    self.freshing = NO;
                }
            });
        } else {
            finishBlock();
        }
    }];
}

- (void)selectConversationIfHasRemoteNotificatoinConvid {
    NSString * remoteNotificationConversationId= [LCCKConversationService sharedInstance].remoteNotificationConversationId;
    if (remoteNotificationConversationId) {
        // 进入之前推送弹框点击的对话
        __block BOOL found = NO;
        [self.dataArray enumerateObjectsUsingBlock:^(AVIMConversation * _Nonnull conversation, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([conversation.conversationId isEqualToString:remoteNotificationConversationId]) {
                //TODO: If has section.
                NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:idx];
                ![LCCKConversationListService sharedInstance].didSelectConversationsListCellBlock ?: [LCCKConversationListService sharedInstance].didSelectConversationsListCellBlock(indexPath, conversation, self.conversationListViewController);
                found = YES;
                *stop = YES;
                return;
            }
        }];
        
        if (!found) {
            LCCKLog(@"not found remoteNofitciaonID");
        }
        [LCCKConversationService sharedInstance].remoteNotificationConversationId = nil;
    }
}

#pragma mark -
#pragma mark - LazyLoad Method

/**
 *  lazy load dataArray
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)dataArray {
    if (_dataArray == nil) {
        _dataArray = @[].mutableCopy;
    }
    return _dataArray;
}

- (UIImage *)imageInBundleForImageName:(NSString *)imageName {
    return ({
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[self class]];
        image;});
}

@end
