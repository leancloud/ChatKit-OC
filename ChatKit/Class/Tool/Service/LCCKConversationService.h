//
//  LCCKConversationService.h
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKServiceDefinition.h"

#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif

@class LCCKMessage;

@class LCCKConversationViewController;

/*!
 * LCCKConversationService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCCKConversationServiceErrorDomain;

@interface LCCKConversationService : LCCKSingleton <LCCKConversationService>

/**
 *  当前正在聊天的 conversationId，当前不在聊天界面则为nil。如果想判断当前是否在对话页面，请判断该值是否为nil。
 */
@property (nonatomic, strong) NSString *currentConversationId;

/**
 *  推送弹框点击时记录的 convid
 */
@property (nonatomic, strong) NSString *remoteNotificationConversationId;

@property (nonatomic, assign, readonly, getter=isChatting) BOOL chatting;

/*!
 * 只要进过聊天页面，这个值总不为nil。当前不在聊天界面则为nil，这是因为考虑到可能会在对话页面，Present其它页面，比如联系人列表，需要用到currentConversation信息，所以如果想判断当前是否在对话页面，请判断currentConversationId是否为nil。
 */
@property (nonatomic, strong) AVIMConversation *currentConversation;

/*!
 *  根据 conversationId 获取对话
 *  @param conversationId   对话的 id
 *  @param callback
 */
- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(LCCKConversationResultBlock)callback;
- (void)fetchConversationsWithConversationIds:(NSSet *)conversationIds callback:(LCCKArrayResultBlock)callback;

/*!
 *  根据 peerId 获取对话,
 *  @attention  This will create new If not exist.
 *  @param peerId   对方的 id
 *  @param callback
 */
- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(LCCKConversationResultBlock)callback;

- (void)sendMessage:(AVIMTypedMessage*)message
       conversation:(AVIMConversation *)conversation
      progressBlock:(AVProgressBlock)progressBlock
           callback:(LCCKBooleanResultBlock)block;

- (void)sendMessage:(AVIMTypedMessage*)message
       conversation:(AVIMConversation *)conversation
            options:(AVIMMessageSendOption)options
      progressBlock:(AVProgressBlock)progressBlock
           callback:(LCCKBooleanResultBlock)block;

- (void)queryTypedMessagesWithConversation:(AVIMConversation *)conversation timestamp:(int64_t)timestamp limit:(NSInteger)limit block:(LCCKArrayResultBlock)block;

/**
 *  删除对话对应的UIProfile缓存，比如当用户信息发生变化时
 *  @param  conversation 对话，可以是单聊，也可是群聊
 */
- (void)removeCacheForConversationId:(NSString *)conversationID;
- (void)updateConversationAsRead;

#pragma mark - 最近对话的本地缓存，最近对话将保存在本地数据库中
///=============================================================================
/// @name 最近对话的本地缓存，最近对话将保存在本地数据库中
///=============================================================================

/**
 *  会在 openClient 时调用
 *  @param path 跟自己的clientId相关的数据库路径
 */
- (void)setupDatabaseWithUserId:(NSString *)userId;

/**
 *  插入一条最近对话
 *  @param conversation
 */
- (void)insertRecentConversation:(AVIMConversation *)conversation;
- (void)insertRecentConversation:(AVIMConversation *)conversation shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;

- (void)increaseUnreadCount:(NSUInteger)increaseUnreadCount withConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;
/**
 *  更新 mentioned 值，当接收到消息发现 @了我的时候，设为 YES，进入聊天页面，设为 NO
 *  @param mentioned  要更新的值
 *  @param conversation 相应对话
 */
- (void)updateMentioned:(BOOL)mentioned conversationId:(NSString *)conversationId;
- (void)updateMentioned:(BOOL)mentioned conversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;
/**
 *  更新 draft 值
 *  @param draft  要更新的值
 *  @param conversation 相应对话
 */
- (void)updateDraft:(NSString *)draft conversationId:(NSString *)conversationId;
- (void)updateDraft:(NSString *)draft conversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;

/**
 *  更新每条最近对话记录里的 conversation 值，也即某对话的名字、成员可能变了，需要更新应用打开时，第一次加载最近对话列表时，会去向服务器要对话的最新数据，然后更新
 *  @param conversations 要更新的对话
 */
- (void)updateRecentConversation:(NSArray *)conversations;
- (void)updateRecentConversation:(NSArray *)conversations shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished;

/**
 *  从数据库查找所有的对话，即所有的最近对话
 *  @return 对话数据
 */
- (NSArray *)allRecentConversations;

/**
 *  判断某对话是否存在于本地数据库。接收到消息的时候用，sdk 传过来的对话的members 等数据可能是空的，如果本地数据库存在该对话，则不去服务器请求对话了。如果不存在，则向服务器请求对话的元数据。使得在最近对话列表，取出对话的时候，对话都有元数据。
 *  @param conversation 某对话
 *  @return
 */
- (BOOL)isRecentConversationExistWithConversationId:(NSString *)conversationId;

- (NSString *)draftWithConversationId:(NSString *)conversationId;

#pragma mark - FailedMessageStore
///=============================================================================
/// @name FailedMessageStore
///=============================================================================

/*!
 *  失败消息的管理类，职责：
 * 新建一个表 ，保存每个对话失败的消息。(message, convid)
 * 每次进入聊天的时候，发现如果聊天连通，则把失败的消息发送出去。如果不通，则显示在列表后面。
 * 重发的时候，如果重发成功，则消除表里的记录。失败则不做操作。
 * 发送消息的时候，如果发送失败，则往失败的消息表里存一条记录。
 * 该类主要维护了两张表：
 
 表： failed_messages的结构如下：
 
 id       | conversationId | message
 -------------|----------------|-------------
 
 表：conversations的结构如下：
 
 id     |     data    | unreadCount |  mentioned
 -------------|-------------|-------------|-------------
 
 */

/**
 *  发送消息失败时调用
 *  @param message 相应的消息
 */
- (void)insertFailedMessage:(AVIMTypedMessage *)message;
- (void)insertFailedLCCKMessage:(LCCKMessage *)message;
/**
 *  重发成功的时候调用
 *  @param recordId 记录的 id
 *  @return
 */
- (BOOL)deleteFailedMessageByRecordId:(NSString *)recordId;

/**
 *  查找失败的消息。进入聊天页面时调用，若聊天服务连通，则把失败的消息重发，否则，加在列表尾部。
 *  @param conversationId 对话的 id
 *  @return 消息数组
 */
- (NSArray<LCCKMessage *> *)failedMessagesByConversationId:(NSString *)conversationId;

- (NSArray<LCCKMessage *> *)failedMessageIdsByConversationId:(NSString *)conversationId;

- (NSArray<LCCKMessage *> *)failedMessagesByMessageIds:(NSArray *)messageIds;

+ (void)cacheFileTypeMessages:(NSArray<AVIMTypedMessage *> *)messages callback:(AVBooleanResultBlock)callback;

@end
