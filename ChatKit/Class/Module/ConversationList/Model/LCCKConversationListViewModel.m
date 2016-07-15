//
//  LCCKConversationListViewModel.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKConversationListViewModel.h"
#import "LCCKConversationListCell.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKUserDelegate.h"
#import "LCCKUserSystemService.h"
#import "LCCKConversationListViewController.h"
#import "LCCKChatUntiles.h"
#import "AVIMConversation+LCCKAddition.h"
#import "LCCKLastMessageTypeManager.h"
#import "NSDate+LCCKDateTools.h"
#import "MJRefresh.h"
#import "LCCKConversationListService.h"
#import "UIImage+LCCKExtension.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
    #import <SDWebImage/UIImageView+WebCache.h>
#else
    #import "UIImageView+WebCache.h"
#endif



@interface LCCKConversationListViewModel ()

@property (nonatomic, strong) LCCKConversationListViewController *conversationListViewController;

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
    _conversationListViewController = conversationListViewController;
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    __block NSString *displayName = nil;
    __block NSURL *avatarURL = nil;
    NSString *peerId = nil;
    if (conversation.lcck_type == LCCKConversationTypeSingle) {
        peerId = conversation.lcck_peerId;
    } else {
        peerId = conversation.lcck_lastMessage.clientId;
    }
    if (peerId) {
        [self asyncCacheElseNetLoadCell:cell identifier:conversation.lcck_displayName peerId:peerId name:&displayName avatarURL:&avatarURL];
    }
    if (conversation.lcck_type == LCCKConversationTypeSingle) {
        [cell.avatarImageView sd_setImageWithURL:avatarURL placeholderImage:[self imageInBundleForImageName:@"Placeholder_Avatar" ]];
    } else {
        [cell.avatarImageView setImage:[self imageInBundleForImageName:@"Placeholder_Group"]];
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
    AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
    NSArray *editActions = [NSArray array];
    if (conversationEditActionBlock) {
        editActions = conversationEditActionBlock(indexPath, [self defaultRightButtons], conversation, self.conversationListViewController);
    } else {
        editActions = [self defaultRightButtons];
    }
    return editActions;
}

- (void)asyncCacheElseNetLoadCell:(LCCKConversationListCell *)cell identifier:(NSString *)identifier peerId:(NSString *)peerId name:(NSString **)name avatarURL:(NSURL **)avatarURL {
    NSError *error = nil;
    cell.identifier = identifier;
    [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:peerId name:name avatarURL:avatarURL error:&error];
    if (error) {
//        NSLog(@"%@", error);
    }
    if (!*name) {
        if (peerId != NULL) {
            *name = peerId;
        }
        __weak __typeof(self) weakSelf = self;
        __weak __typeof(cell) weakCell = cell;
        [[LCCKUserSystemService sharedInstance] getProfileInBackgroundForUserId:peerId callback:^(id<LCCKUserDelegate> user, NSError *error) {
            if (!error && [weakCell.identifier isEqualToString:user.userId]) {
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
                                              title:NSLocalizedStringFromTable(@"Delete", @"LCChatKitString", @"Delete")
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
    [self refresh];
    ![LCCKConversationListService sharedInstance].didSelectConversationsListCellBlock ?: [LCCKConversationListService sharedInstance].didSelectConversationsListCellBlock(indexPath, conversation, self.conversationListViewController);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
    LCCKHeightForRowBlock heightForRowBlock = [[LCCKConversationListService sharedInstance] heightForRowBlock];
    if (heightForRowBlock) {
        return heightForRowBlock(tableView, indexPath, conversation);
    }
    return LCCKConversationListCellDefaultHeight;
}

#pragma mark - refresh

- (void)refresh {
    [[LCCKConversationListService sharedInstance] findRecentConversationsWithBlock:^(NSArray *conversations, NSInteger totalUnreadCount, NSError *error) {
        dispatch_block_t finishBlock = ^{
            [self.conversationListViewController.tableView.mj_header endRefreshing];
            if ([self.conversationListViewController filterAVIMError:error]) {
                self.dataArray = [NSMutableArray arrayWithArray:conversations];
                [self.conversationListViewController.tableView reloadData];
                ![LCCKConversationListService sharedInstance].markBadgeWithTotalUnreadCountBlock ?: [LCCKConversationListService sharedInstance].markBadgeWithTotalUnreadCountBlock(totalUnreadCount, self.conversationListViewController.navigationController);
                [self selectConversationIfHasRemoteNotificatoinConvid];
            }
        };
        if([LCCKConversationListService sharedInstance].prepareConversationsWhenLoadBlock) {
            [LCCKConversationListService sharedInstance].prepareConversationsWhenLoadBlock(conversations, ^(BOOL succeeded, NSError *error) {
                if ([self.conversationListViewController filterAVIMError:error]) {
                    finishBlock();
                } else {
                    [self.conversationListViewController.tableView.mj_header endRefreshing];
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
            NSLog(@"not found remoteNofitciaonID");
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
        NSMutableArray *dataArray = [[NSMutableArray alloc] init];
        _dataArray = dataArray;
    }
    return _dataArray;
}

- (UIImage *)imageInBundleForImageName:(NSString *)imageName {
    return ({
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[self class]];
        image;});
}

@end
