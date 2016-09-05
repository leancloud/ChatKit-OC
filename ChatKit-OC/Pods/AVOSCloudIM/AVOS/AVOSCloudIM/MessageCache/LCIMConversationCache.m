//
//  LCIMConversationCache.m
//  AVOS
//
//  Created by Tang Tianyong on 8/31/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCIMConversationCache.h"
#import "LCIMConversationCacheStore.h"
#import "LCIMConversationQueryCacheStore.h"
#import "AVIMConversation.h"

@interface LCIMConversationCache ()

@property (nonatomic, strong) LCIMConversationCacheStore *cacheStore;
@property (nonatomic, strong) LCIMConversationQueryCacheStore *queryCacheStore;

@end

@implementation LCIMConversationCache

- (instancetype)initWithClientId:(NSString *)clientId {
    self = [super init];

    if (self) {
        _clientId = [clientId copy];
    }

    return self;
}

- (AVIMConversation *)conversationForId:(NSString *)conversationId {
    return [self.cacheStore conversationForId:conversationId];
}

- (NSArray *)conversationIdsFromConversations:(NSArray *)conversations {
    NSMutableArray *conversationIds = [NSMutableArray array];

    for (AVIMConversation *conversation in conversations) {
        if (conversation.conversationId) {
            [conversationIds addObject:conversation.conversationId];
        }
    }

    return conversationIds;
}

- (void)cacheConversations:(NSArray *)conversations maxAge:(NSTimeInterval)maxAge forCommand:(AVIMConversationOutCommand *)command {
    NSArray *conversationIds = [self conversationIdsFromConversations:conversations];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.queryCacheStore cacheConversationIds:conversationIds forCommand:command];
        [self.cacheStore insertConversations:conversations maxAge:maxAge];
    });
}

- (NSArray *)conversationsForCommand:(AVIMConversationOutCommand *)command {
    NSArray *result = nil;
    NSArray *conversationIds = [self.queryCacheStore conversationIdsForCommand:command];

    if ([conversationIds count]) {
        result = [self.cacheStore conversationsForIds:conversationIds];

        if (![result count]) {
            [self.queryCacheStore removeConversationIdsForCommand:command];
        }
    } else if (conversationIds) {
        result = @[];
    } else {
        result = nil;
    }

    return result;
}

- (void)removeConversationForId:(NSString *)conversationId {
    [self.cacheStore deleteConversationForId:conversationId];
}

- (void)removeConversationAndItsMessagesForId:(NSString *)conversationId {
    [self.cacheStore deleteConversationAndItsMessagesForId:conversationId];
}

- (void)cleanAllExpiredConversations {
    [self.cacheStore allExpiredConversations];
}

#pragma mark - Lazy loading

- (LCIMConversationCacheStore *)cacheStore {
    return _cacheStore ?: (
        _cacheStore = [[LCIMConversationCacheStore alloc] initWithClientId:self.clientId]
    );
}

- (LCIMConversationQueryCacheStore *)queryCacheStore {
    return _queryCacheStore ?: (
        _queryCacheStore = [[LCIMConversationQueryCacheStore alloc] initWithClientId:self.clientId]
    );
}

@end
