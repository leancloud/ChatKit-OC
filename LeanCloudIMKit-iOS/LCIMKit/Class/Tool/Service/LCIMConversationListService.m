//
//  LCIMConversationListService.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCIMConversationListService.h"
#import "AVIMConversation+LCIMAddition.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMUserSystemService.h"
#import "LCIMSessionService.h"

@interface LCIMConversationListService()

@property (nonatomic, copy, readwrite) LCIMConversationsListDidSelectItemBlock didSelectItemBlock;
@property (nonatomic, copy, readwrite) LCIMConversationsListDidDeleteItemBlock didDeleteItemBlock;
@property (nonatomic, copy, readwrite) LCIMMarkBadgeWithTotalUnreadCountBlock markBadgeWithTotalUnreadCountBlock;
@property (nonatomic, copy, readwrite) LCIMPrepareConversationsWhenLoadBlock prepareConversationsWhenLoadBlock;
@property (nonatomic, copy, readwrite) LCIMConversationEditActionsBlock conversationEditActionBlock;
@property (nonatomic, copy, readwrite) LCIMHeightForRowBlock heightForRowBlock;
@property (nonatomic, copy, readwrite) LCIMCellForRowBlock cellForRowBlock;
@property (nonatomic, copy, readwrite) LCIMConfigureCellBlock configureCellBlock;

@end

@implementation LCIMConversationListService

/**
 * create a singleton instance of LCIMConversationListService
 */
+ (instancetype)sharedInstance {
    static LCIMConversationListService *_sharedLCIMConversationListService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMConversationListService = [[self alloc] init];
    });
    return _sharedLCIMConversationListService;
}

- (void)findRecentConversationsWithBlock:(LCIMRecentConversationsCallback)block {
    [self selectOrRefreshConversationsWithBlock:^(NSArray *conversations, NSError *error) {
        NSMutableSet *userIds = [NSMutableSet set];
        NSUInteger totalUnreadCount = 0;
        for (AVIMConversation *conversation in conversations) {
            NSArray *lastestMessages = [conversation queryMessagesFromCacheWithLimit:1];
            if (lastestMessages.count > 0) {
                conversation.lcim_lastMessage = lastestMessages[0];
            }
            if (conversation.lcim_type == LCIMConversationTypeSingle) {
                [userIds addObject:conversation.lcim_peerId];
            } else {
                if (conversation.lastMessageAt) {
                    NSString *userId = conversation.lcim_lastMessage.clientId;
                    !userId ?: [userIds addObject:userId];
                }
            }
            if (conversation.muted == NO) {
                totalUnreadCount += conversation.lcim_unreadCount;
            }
        }
        NSArray *sortedRooms = [conversations sortedArrayUsingComparator:^NSComparisonResult(AVIMConversation *conv1, AVIMConversation *conv2) {
            return (NSComparisonResult)(conv2.lcim_lastMessage.sendTimestamp - conv1.lcim_lastMessage.sendTimestamp);
        }];
        !block ?: block(sortedRooms, totalUnreadCount, error);
        [[LCIMUserSystemService sharedInstance] cacheUsersWithIds:userIds callback:^(BOOL succeeded, NSError *error) {
            if (error) {
                NSLog(@"%@",error.localizedDescription);
            }
        }];
    }];
}

- (void)selectOrRefreshConversationsWithBlock:(AVIMArrayResultBlock)block {
    static BOOL refreshedFromServer = NO;
    NSArray *conversations = [[LCIMConversationService sharedInstance] allRecentConversations];
    if (refreshedFromServer == NO && [LCIMSessionService sharedInstance].connect) {
        NSMutableSet *conversationIds = [NSMutableSet set];
        for (AVIMConversation *conversation in conversations) {
            [conversationIds addObject:conversation.conversationId];
        }
        [self fetchConversationsWithConversationIds:conversationIds callback:^(NSArray *objects, NSError *error) {
            if (error) {
                !block ?: block(conversations, nil);
            } else {
                refreshedFromServer = YES;
                [[LCIMConversationService sharedInstance] updateRecentConversation:objects];
                !block ?: block([[LCIMConversationService sharedInstance] allRecentConversations], nil);
            }
        }];
    } else {
        !block ?: block(conversations, nil);
    }
}

- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds callback:(LCIMArrayResultBlock)callback {
    if (conversationIds.count > 0) {
        AVIMConversationQuery *query = [[LCIMSessionService sharedInstance].client conversationQuery];
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
                    NSError *error = [NSError errorWithDomain:LCIMConversationServiceErrorDomain
                                                         code:code
                                                     userInfo:errorInfo];
                    !callback ?: callback(nil, error);
                } else {
                    !callback ?: callback(objects, error);
                }
            }
        }];
    }
}

#pragma mark -
#pragma mark - Setter Method

- (void)setDidSelectItemBlock:(LCIMConversationsListDidSelectItemBlock)didSelectItemBlock {
    _didSelectItemBlock = didSelectItemBlock;
}

- (void)setMarkBadgeWithTotalUnreadCountBlock:(LCIMMarkBadgeWithTotalUnreadCountBlock)markBadgeWithTotalUnreadCountBlock {
    _markBadgeWithTotalUnreadCountBlock = markBadgeWithTotalUnreadCountBlock;
}

- (void)setPrepareConversationsWhenLoadBlock:(LCIMPrepareConversationsWhenLoadBlock)prepareConversationsWhenLoadBlock {
    _prepareConversationsWhenLoadBlock = prepareConversationsWhenLoadBlock;
}

- (void)setDidDeleteItemBlock:(LCIMConversationsListDidDeleteItemBlock)didDeleteItemBlock {
    _didDeleteItemBlock = didDeleteItemBlock;
}

- (void)setConversationEditActionBlock:(LCIMConversationEditActionsBlock)conversationEditActionBlock {
    _conversationEditActionBlock = conversationEditActionBlock;
}

- (void)setHeightForRowBlock:(LCIMHeightForRowBlock)heightForRowBlock {
    _heightForRowBlock = heightForRowBlock;
}

- (void)setCellForRowBlock:(LCIMCellForRowBlock)cellForRowBlock {
    _cellForRowBlock = cellForRowBlock;
}

-(void)setConfigureCellBlock:(LCIMConfigureCellBlock)configureCellBlock {
    _configureCellBlock = configureCellBlock;
}

@end
