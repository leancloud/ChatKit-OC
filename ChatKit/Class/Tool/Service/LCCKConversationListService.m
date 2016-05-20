//
//  LCCKConversationListService.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKConversationListService.h"
#import "AVIMConversation+LCCKAddition.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"

@interface LCCKConversationListService()

@property (nonatomic, copy, readwrite) LCCKConversationsListDidSelectItemBlock didSelectItemBlock;
@property (nonatomic, copy, readwrite) LCCKConversationsListDidDeleteItemBlock didDeleteItemBlock;
@property (nonatomic, copy, readwrite) LCCKMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock;
@property (nonatomic, copy, readwrite) LCCKPrepareConversationsWhenLoadBlock prepareConversationsWhenLoadBlock;
@property (nonatomic, copy, readwrite) LCCKConversationEditActionsBlock conversationEditActionBlock;
@property (nonatomic, copy, readwrite) LCCKHeightForRowBlock heightForRowBlock;
@property (nonatomic, copy, readwrite) LCCKCellForRowBlock cellForRowBlock;
@property (nonatomic, copy, readwrite) LCCKConfigureCellBlock configureCellBlock;

@end

@implementation LCCKConversationListService

- (void)findRecentConversationsWithBlock:(LCCKRecentConversationsCallback)block {
    [self selectOrRefreshConversationsWithBlock:^(NSArray *conversations, NSError *error) {
        NSMutableSet *userIds = [NSMutableSet set];
        NSUInteger totalUnreadCount = 0;
        for (AVIMConversation *conversation in conversations) {
            NSArray *lastestMessages = [conversation queryMessagesFromCacheWithLimit:1];
            if (lastestMessages.count > 0) {
                conversation.lcck_lastMessage = lastestMessages[0];
            }
            if (conversation.lcck_type == LCCKConversationTypeSingle) {
                [userIds addObject:conversation.lcck_peerId];
            } else {
                if (conversation.lastMessageAt) {
                    NSString *userId = conversation.lcck_lastMessage.clientId;
                    (!userId || !conversation.lcck_lastMessage) ?: [userIds addObject:userId];
                }
            }
            if (conversation.muted == NO) {
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
        
        [[LCCKUserSystemService sharedInstance] cacheUsersWithIds:userIds callback:^(BOOL succeeded, NSError *error) {
            if (error) {
//                NSLog(@"%@",error.localizedDescription);
            }
        }];
    }];
}

- (void)selectOrRefreshConversationsWithBlock:(AVIMArrayResultBlock)block {
    static BOOL refreshedFromServer = NO;
    NSArray *conversations = [[LCCKConversationService sharedInstance] allRecentConversations];
    if (conversations.count == 0) {
        !block ?: block(conversations, nil);
        return;
    }
    if (refreshedFromServer == NO && [LCCKSessionService sharedInstance].connect) {
        NSMutableSet *conversationIds = [NSMutableSet set];
        for (AVIMConversation *conversation in conversations) {
            [conversationIds addObject:conversation.conversationId];
        }
        [self fetchConversationsWithConversationIds:conversationIds callback:^(NSArray *objects, NSError *error) {
            if (error) {
                !block ?: block(conversations, nil);
            } else {
                refreshedFromServer = YES;
                [[LCCKConversationService sharedInstance] updateRecentConversation:objects];
                !block ?: block([[LCCKConversationService sharedInstance] allRecentConversations], nil);
            }
        }];
    } else {
        !block ?: block(conversations, nil);
    }
}

- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds
                                     callback:(LCCKArrayResultBlock)callback {
        AVIMConversationQuery *query = [[LCCKSessionService sharedInstance].client conversationQuery];
        [query whereKey:@"objectId" containedIn:[conversationIds allObjects]];
        query.cachePolicy = kAVCachePolicyNetworkElseCache;
        query.limit = 1000;  // default limit:10
        [query findConversationsWithCallback: ^(NSArray *objects, NSError *error) {
            if (error) {
                !callback ?: callback(nil, error);
            } else {
                if (objects.count == 0) {
                    NSString *errorReasonText = [NSString stringWithFormat:@"conversations in %@  are not exists", conversationIds];
                    NSInteger code = 0;
                    NSDictionary *errorInfo = @{
                                                @"code":@(code),
                                                NSLocalizedDescriptionKey : errorReasonText,
                                                };
                    NSError *error = [NSError errorWithDomain:LCCKConversationServiceErrorDomain
                                                         code:code
                                                     userInfo:errorInfo];
                    !callback ?: callback(nil, error);
                } else {
                    !callback ?: callback(objects, error);
                }
            }
        }];
}

#pragma mark -
#pragma mark - Setter Method

- (void)setDidSelectItemBlock:(LCCKConversationsListDidSelectItemBlock)didSelectItemBlock {
    _didSelectItemBlock = didSelectItemBlock;
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCCKMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    _markBadgeWithTotalUnreadCountBlock = markBadgeWithTotalUnreadCountBlock;
}

- (void)setPrepareConversationsWhenLoadBlock:(LCCKPrepareConversationsWhenLoadBlock)prepareConversationsWhenLoadBlock {
    _prepareConversationsWhenLoadBlock = prepareConversationsWhenLoadBlock;
}

- (void)setDidDeleteItemBlock:(LCCKConversationsListDidDeleteItemBlock)didDeleteItemBlock {
    _didDeleteItemBlock = didDeleteItemBlock;
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

-(void)setConfigureCellBlock:(LCCKConfigureCellBlock)configureCellBlock {
    _configureCellBlock = configureCellBlock;
}

@end
