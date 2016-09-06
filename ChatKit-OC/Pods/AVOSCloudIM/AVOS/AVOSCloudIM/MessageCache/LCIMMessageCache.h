//
//  LCIMMessageCache.h
//  AVOS
//
//  Created by Tang Tianyong on 5/5/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVIMMessage;

@interface LCIMMessageCache : NSObject

@property (readonly) NSString *clientId;

/*!
 * Return a cache for specified client.
 * @param clientId Client id of the cache.
 */
+ (instancetype)cacheWithClientId:(NSString *)clientId;

/*!
 * Query message before specified conditions.
 * @param timestamp Start timestamp.
 * @param messageId Start messageId, if message not found, use the timestamp instead.
 * @param conversationId Conversation which messages belong to.
 * @param limit Max number of messages to query.
 * @param complete Wether the messages queried is complete.
 */
- (NSArray *)messagesBeforeTimestamp:(int64_t)timestamp
                           messageId:(NSString *)messageId
                      conversationId:(NSString *)conversationId
                               limit:(NSUInteger)limit
                          continuous:(BOOL *)continuous;

/*!
 * Add continuous messages returned from server.
 * The messages should be continuous, in ascending order by timestamp.
 * @param messages Messages which should be added.
 * @param conversationId Conversation which the messages belong to.
 */
- (void)addContinuousMessages:(NSArray *)messages forConversationId:(NSString *)conversationId;

/*!
 * Remove messages from specified conversation.
 * @param messages Messages which should be removed.
 * @param conversationId Conversation which the messages belong to.
 */
- (void)deleteMessages:(NSArray *)messages forConversationId:(NSString *)conversationId;

/*!
 * Newer message of specified message.
 * @param message Message object.
 * @param conversationId Conversation id of message.
 */
- (AVIMMessage *)nextMessageForMessage:(AVIMMessage *)message conversationId:(NSString *)conversationId;

/*!
 * Fetch latest messages of conversation.
 * @param conversationId Conversation id of messages.
 * @param limit Number of messages.
 */
- (NSArray *)latestMessagesForConversationId:(NSString *)conversationId limit:(NSUInteger)limit;

/*!
 * Check wether cache contains message.
 * @param message Message which for checking.
 * @param conversationId Conversation id of message.
 * @return YES if cache contains message, otherwise NO.
 */
- (BOOL)containMessage:(AVIMMessage *)message forConversationId:(NSString *)conversationId;

/*!
 * Update message without it bearkpoint.
 * @param message Message which for updating.
 * @param conversationId Conversation id of message.
 * @return void.
 */
- (void)updateMessage:(AVIMMessage *)message forConversationId:(NSString *)conversationId;

/*!
 * Clean cache for conversation.
 * @param conversationId Conversation id of the cache, can not be nil.
 */
- (void)cleanCacheForConversationId:(NSString *)conversationId;

/*!
 * Clean all cache of client.
 */
- (void)cleanAllCache;

@end
