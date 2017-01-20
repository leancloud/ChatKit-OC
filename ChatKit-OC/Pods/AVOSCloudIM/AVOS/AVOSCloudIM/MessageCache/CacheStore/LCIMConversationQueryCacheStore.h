//
//  LCIMConversationQueryCacheStore.h
//  AVOS
//
//  Created by Tang Tianyong on 8/31/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCKeyValueStore.h"

@class AVIMConversationOutCommand;

@interface LCIMConversationQueryCacheStore : LCKeyValueStore

@property (copy, readonly) NSString *clientId;

- (instancetype)initWithClientId:(NSString *)clientId;

- (void)cacheConversationIds:(NSArray *)conversationIds forCommand:(AVIMConversationOutCommand *)command;

- (void)removeConversationIdsForCommand:(AVIMConversationOutCommand *)command;

/*!
 * Get conversation id list for a given command.
 * @param command AVIMConversationOutCommand object.
 * @return A conversation id list or nil if cache not found.
 */
- (NSArray *)conversationIdsForCommand:(AVIMConversationOutCommand *)command;

@end
