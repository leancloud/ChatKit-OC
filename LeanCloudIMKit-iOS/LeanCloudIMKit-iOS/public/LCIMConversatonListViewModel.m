//
//  LCIMConversatonListViewModel.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMConversatonListViewModel.h"
#import "LCIMConversatonListCell.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMUserModelDelegate.h"
#import "YYKit.h"
#import "LCIMUserSystemService.h"
#import "LCIMConversationListViewController.h"
#import "LCIMChatUntiles.h"
#import "AVIMConversation+LCIMAddition.h"
#import "LCIMLastMessageTypeManager.h"
#import "NSDate+DateTools.h"
#import "MJRefresh.h"
#import "LCIMConversationListService.h"

@interface LCIMConversatonListViewModel ()

@property (nonatomic, strong) LCIMConversationListViewController *conversationListViewController;

@end

@implementation LCIMConversatonListViewModel

#pragma mark -
#pragma mark - LifeCycle Method

- (instancetype)initWithConversationListViewController:(LCIMConversationListViewController *)conversationListViewController {
    self = [super init];
    if (!self) {
        return nil;
    }
    // 当在其它 Tab 的时候，收到消息 badge 增加，所以需要一直监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:LCIMNotificationMessageReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:LCIMNotificationUnreadsUpdated object:nil];
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
    LCIMConversatonListCell *cell = [LCIMConversatonListCell dequeueOrCreateCellByTableView:tableView];
    AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
    NSError *error = nil;
    NSString *peerId = conversation.lcim_peerId;
    cell.identifier = peerId;
    __block NSString *displayName = nil;
    __block NSURL *avatorURL = nil;
    [[LCIMUserSystemService sharedInstance] getCachedProfileIfExists:peerId name:&displayName avatorURL:&avatorURL error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    if (!displayName) {
        displayName = peerId;
        __weak __typeof(self) weakSelf = self;
        __weak __typeof(cell) weakCell = cell;
        [[LCIMUserSystemService sharedInstance] getProfileInBackgroundForUserId:peerId callback:^(id<LCIMUserModelDelegate> user, NSError *error) {
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
    
    if (conversation.lcim_type == LCIMConversationTypeSingle) {
        cell.nameLabel.text = displayName;
        [cell.avatorImageView setImageWithURL:avatorURL placeholder:[self imageInBundleForImageName:@"Placeholder_Avator"]];
    } else {
        //TODO:
        [cell.avatorImageView setImage:[self imageInBundleForImageName:@"Placeholder_Avator"]];
        cell.nameLabel.text = conversation.lcim_displayName;
    }
    
    if (conversation.lcim_lastMessage) {
        cell.messageTextLabel.attributedText = [LCIMLastMessageTypeManager attributedStringWithMessage:conversation.lcim_lastMessage conversation:conversation userName:displayName];
        cell.timestampLabel.text = [[NSDate dateWithTimeIntervalSince1970:conversation.lcim_lastMessage.sendTimestamp / 1000] timeAgoSinceNow];
    }
    if (conversation.lcim_unreadCount > 0) {
        if (conversation.muted) {
            cell.litteBadgeView.hidden = NO;
        } else {
            //FIXME:
            //            cell.badgeView.badgeText = [NSString stringWithFormat:@"%@", @(conversation.lcim_unreadCount)];
        }
    }
    //    if ([self.chatListDelegate respondsToSelector:@selector(configureCell:atIndexPath:withConversation:)]) {
    //        [self.chatListDelegate configureCell:cell atIndexPath:indexPath withConversation:conversation];
    //    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
        [[LCIMConversationService sharedInstance] deleteConversation:conversation];
        [self refresh];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return true;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AVIMConversation *conversation = [self.dataArray objectAtIndex:indexPath.row];
    [conversation markAsReadInBackground];
    [self refresh];
    !self.conversationListViewController.didSelectItemBlock ?: self.conversationListViewController.didSelectItemBlock(conversation);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [LCIMConversatonListCell heightOfCell];
}

#pragma mark - refresh

- (void)refresh {
    [[LCIMConversationListService sharedInstance] findRecentConversationsWithBlock:^(NSArray *conversations, NSInteger totalUnreadCount, NSError *error) {
        dispatch_block_t finishBlock = ^{
            [self.conversationListViewController.tableView.mj_header endRefreshing];
            if ([self.conversationListViewController filterAVIMError:error]) {
                self.dataArray = [NSMutableArray arrayWithArray:conversations];
                [self.conversationListViewController.tableView reloadData];
                !self.conversationListViewController.markBadgeWithTotalUnreadCountBlock ?: self.conversationListViewController.markBadgeWithTotalUnreadCountBlock(totalUnreadCount);
                [self selectConversationIfHasRemoteNotificatoinConvid];
            }
        };
        if(self.conversationListViewController.prepareConversationsWhenLoadBlock) {
            self.conversationListViewController.prepareConversationsWhenLoadBlock(conversations, ^(BOOL succeeded, NSError *error) {
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
    NSString * remoteNotificationConversationId= [LCIMConversationService sharedInstance].remoteNotificationConversationId;
    if (remoteNotificationConversationId) {
        // 进入之前推送弹框点击的对话
        __block BOOL found = NO;
        [self.dataArray enumerateObjectsUsingBlock:^(AVIMConversation * _Nonnull conversation, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([conversation.conversationId isEqualToString:remoteNotificationConversationId]) {
                !self.conversationListViewController.didSelectItemBlock ?: self.conversationListViewController.didSelectItemBlock(conversation);
                found = YES;
                *stop = YES;
                return;
            }
        }];
        
        if (!found) {
            NSLog(@"not found remoteNofitciaonID");
        }
        [LCIMConversationService sharedInstance].remoteNotificationConversationId = nil;
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
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        image;});
}

@end
