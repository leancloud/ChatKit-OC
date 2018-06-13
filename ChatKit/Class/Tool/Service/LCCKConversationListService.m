//
//  LCCKConversationListService.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

//TODO:
///**
// *  在没有数据时显示该view，占据Controller的View整个页面
// */
//@property (nonatomic, strong) UIView *viewForNoData;
///**
// *  设置某个对话的最近消息内容后的回调
// *  @param conversation 需要设置最近消息内容的对话
// *  @return 无需自定义最近消息内容返回nil
// */
//typedef NSString *(^LCCKConversationsLatestMessageContent)(AVIMConversation *conversation);
//
///**
// *  设置某个对话的最近消息内容后的回调
// */
//@property (nonatomic, copy, readonly) LCCKConversationsLatestMessageContent latestMessageContentBlock;
//
///**
// *  设置某个对话的最近消息内容后的回调
// */
//- (void)setLatestMessageContentBlock:(LCCKConversationsLatestMessageContent)latestMessageContentBlock;


#import "LCCKConversationListService.h"
#import "AVIMConversation+LCCKExtension.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"
#import "AVIMMessage+LCCKExtension.h"

@implementation LCCKConversationListService
@synthesize didSelectConversationsListCellBlock = _didSelectConversationsListCellBlock;
@synthesize didDeleteConversationsListCellBlock = _didDeleteConversationsListCellBlock;
@synthesize conversationEditActionBlock = _conversationEditActionBlock;
@synthesize markBadgeWithTotalUnreadCountBlock = _markBadgeWithTotalUnreadCountBlock;

- (void)findRecentConversationsWithBlock:(LCCKRecentConversationsCallback)block {
    [self selectOrRefreshConversationsWithBlock:^(NSArray *conversations, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableSet *userIds = [NSMutableSet set];
        NSUInteger totalUnreadCount = 0;
        for (AVIMConversation *conversation in conversations) {
//            NSArray *lastestMessages = [conversation queryMessagesFromCacheWithLimit:1];
//            if (lastestMessages.count > 0) {
//                AVIMTypedMessage *avimTypedMessage = [lastestMessages[0] lcck_getValidTypedMessage];
//                
//                id visiableForPartClientIds = [avimTypedMessage.attributes
//                                                     valueForKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
//                BOOL isArray = [visiableForPartClientIds isKindOfClass:[NSArray class]];
//                BOOL isString = [visiableForPartClientIds isKindOfClass:[NSString class]];
//                if (!visiableForPartClientIds) {
//                    conversation.lcck_lastMessage = avimTypedMessage;
//                } else if (isArray && ([(NSArray *)visiableForPartClientIds count] > 0)) {
//                    BOOL visiableForCurrentClientId =
//                    [visiableForPartClientIds containsObject:[LCChatKit sharedInstance].clientId];
//                    if (visiableForCurrentClientId) {
//                        conversation.lcck_lastMessage = avimTypedMessage;
//                    }
//                } else if (isString && ([(NSString *)visiableForPartClientIds length] > 0)) {
//                    if ([visiableForPartClientIds isEqualToString:[LCChatKit sharedInstance].clientId]) {
//                        conversation.lcck_lastMessage = avimTypedMessage;
//                    }
//                }
//            }
            if (conversation.lcck_type == LCCKConversationTypeSingle) {
                [userIds addObject:conversation.lcck_peerId];
            } else {
                if (conversation.lastMessageAt) {
                    NSString *userId = conversation.lcck_lastMessage.clientId;
                    (!userId || !conversation.lcck_lastMessage) ?: [userIds addObject:userId];
                }
            }
            if (conversation.muted == NO && conversation.lcck_unreadCount > 0) {
                totalUnreadCount += conversation.lcck_unreadCount;
            }
        }
        NSArray *sortedRooms = [conversations sortedArrayUsingComparator:^NSComparisonResult(AVIMConversation *conv1, AVIMConversation *conv2) {
            return (NSComparisonResult)(conv2.lcck_lastMessage.sendTimestamp - conv1.lcck_lastMessage.sendTimestamp);
        }];
        dispatch_async(dispatch_get_main_queue(),^{
            !block ?: block(sortedRooms, totalUnreadCount, error);
        });
        
        if (userIds.count == 0) {
            return;
        }
        
        [[LCCKUserSystemService sharedInstance] cacheUsersWithIds:userIds callback:nil];
        });
    }];
}

- (void)fetchRelationConversationsFromServer:(AVIMArrayResultBlock)block {
    AVIMClient *client = [LCCKSessionService sharedInstance].client;
    AVIMConversationQuery *orConversationQuery = [client conversationQuery];

//    
//    AVIMConversationQuery *query2 = [client conversationQuery];
////    query2.limit = 10;
//    [query2 whereKey:@"sys" equalTo:@(YES)];
//    
//    AVIMConversationQuery *orConversationQuery = [AVIMConversationQuery orQueryWithSubqueries:@[ query1, query2 ]];
    orConversationQuery.cachePolicy = kAVIMCachePolicyIgnoreCache;
    orConversationQuery.option = AVIMConversationQueryOptionWithMessage;
    [orConversationQuery findConversationsWithCallback:^(NSArray<AVIMConversation *> * _Nullable conversations, NSError * _Nullable error) {
        !block ?: block(conversations, error);
    }];
}

static BOOL refreshedFromServer = NO;

- (void)selectOrRefreshConversationsWithBlock:(AVIMArrayResultBlock)block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSArray  *conversations = [[LCCKConversationService sharedInstance] allRecentConversations];
        if (refreshedFromServer == NO && [LCCKSessionService sharedInstance].connect) {
            NSMutableSet *conversationIds = [NSMutableSet set];
            for (AVIMConversation *conversation in conversations) {
                [conversationIds addObject:conversation.conversationId];
            }
            [[LCCKConversationService sharedInstance] fetchConversationsWithConversationIds:conversationIds callback:^(NSArray<AVIMConversation *> *objects, NSError *error) {
                if (error) {
                        !block ?: block(conversations, error);
                } else {
                    refreshedFromServer = YES;
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                        [[LCCKConversationService sharedInstance] updateRecentConversation:objects];
                        dispatch_async(dispatch_get_main_queue(),^{
                            !block ?: block(conversations, error);
                        });
                    });
                    
                }
            }];
        } else {
            dispatch_async(dispatch_get_main_queue(),^{
                !block ?: block(conversations, nil);
            });
        }
    });
}
                   
#pragma mark -
#pragma mark - Setter Method

- (void)setDidSelectConversationsListCellBlock:(LCCKDidSelectConversationsListCellBlock)didSelectConversationsListCellBlock {
    _didSelectConversationsListCellBlock = didSelectConversationsListCellBlock;
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCCKMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    _markBadgeWithTotalUnreadCountBlock = markBadgeWithTotalUnreadCountBlock;
}

- (void)setPrepareConversationsWhenLoadBlock:(LCCKPrepareConversationsWhenLoadBlock)prepareConversationsWhenLoadBlock {
    _prepareConversationsWhenLoadBlock = prepareConversationsWhenLoadBlock;
}

- (void)setDidDeleteConversationsListCellBlock:(LCCKDidDeleteConversationsListCellBlock)didDeleteConversationsListCellBlock {
    _didDeleteConversationsListCellBlock = didDeleteConversationsListCellBlock;
}

- (void)setConversationEditActionBlock:(LCCKConversationEditActionsBlock)conversationEditActionBlock {
    _conversationEditActionBlock = conversationEditActionBlock;
}

- (void)setHeightForRowBlock:(LCCKHeightForRowBlock)heightForRowBlock {
    _heightForRowBlock = heightForRowBlock;
}

- (void)setCellForRowBlock:(LCCKCellForRowBlock)cellForRowBlock {
    _cellForRowBlock = cellForRowBlock;
}

- (void)setConfigureCellBlock:(LCCKConfigureCellBlock)configureCellBlock {
    _configureCellBlock = configureCellBlock;
}

@end
