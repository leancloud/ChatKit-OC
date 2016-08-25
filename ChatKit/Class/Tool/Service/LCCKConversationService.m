 //
//  LCCKConversationService.m
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKConversationService.h"
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#if __has_include(<FMDB/FMDB.h>)
#import <FMDB/FMDB.h>
#else
#import "FMDB.h"
#endif

#import "AVIMConversation+LCCKExtension.h"
#import "LCCKConversationViewController.h"
#import "LCCKConversationListViewController.h"
#import "LCCKMessage.h"
#import "LCCKConversationListService.h"
#import "AVIMMessage+LCCKExtension.h"

NSString *const LCCKConversationServiceErrorDomain = @"LCCKConversationServiceErrorDomain";

@interface LCCKConversationService()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) AVIMClient *client;

@end

@implementation LCCKConversationService
@synthesize currentConversation = _currentConversation;
@synthesize fetchConversationHandler = _fetchConversationHandler;
@synthesize conversationInvalidedHandler = _conversationInvalidedHandler;
@synthesize loadLatestMessagesHandler = _loadLatestMessagesHandler;
@synthesize filterMessagesBlock = _filterMessagesBlock;

/**
 *  根据 conversationId 获取对话
 *  @param convid   对话的 id
 *  @param callback
 */
- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(LCCKConversationResultBlock)callback {
    NSAssert(conversationId.length > 0, @"Conversation id is nil");
    AVIMConversation *conversation = [self.client conversationForId:conversationId];
    if (conversation) {
        !callback ?: callback(conversation, nil);
        return;
    }
    
    NSSet *conversationSet = [NSSet setWithObject:conversationId];
    [self fetchConversationsWithConversationIds:conversationSet callback:^(NSArray *objects, NSError *error) {
        if (error) {
            !callback ?: callback(nil, error);
        } else {
            if (objects.count == 0) {
                NSString *errorReasonText = [NSString stringWithFormat:@"conversation of %@ are not exists", conversationId];
                NSInteger code = 0;
                NSDictionary *errorInfo = @{
                                            @"code" : @(code),
                                            NSLocalizedDescriptionKey : errorReasonText,
                                            };
                NSError *error = [NSError errorWithDomain:LCCKConversationServiceErrorDomain
                                                     code:code
                                                 userInfo:errorInfo];
                !callback ?: callback(nil, error);
            } else {
                !callback ?: callback(objects[0], error);
            }
        }
    }];
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

- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback {
    if (![LCCKSessionService sharedInstance].connect) {
        NSInteger code = 0;
        NSString *errorReasonText = @"Session not opened";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKConversationServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        
        !callback ?: callback(nil, error);
        return;
    }
    if ([peerId isEqualToString:[[LCCKSessionService sharedInstance] clientId]]) {
        NSString *formatString = @"\n\n\
        ------ BEGIN NSException Log ---------------\n \
        class name: %@                              \n \
        ------line: %@                              \n \
        ----reason: %@                              \n \
        ------ END -------------------------------- \n\n";
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__),
                            @"You cannot chat with yourself"];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    NSString *myId = [LCCKSessionService sharedInstance].clientId;
    NSArray *array = @[ myId, peerId ];
    [self fetchConversationWithMembers:array type:LCCKConversationTypeSingle callback:callback];
}

- (void)checkDuplicateValueOfArray:(NSArray *)array {
    NSSet *set = [NSSet setWithArray:array];
    if (set.count != array.count) {
        [NSException raise:NSInvalidArgumentException format:@"The array has duplicate value"];
    }
}

- (void)fetchConversationWithMembers:(NSArray *)members type:(LCCKConversationType)type callback:(AVIMConversationResultBlock)callback {
    if ([members containsObject:[LCCKSessionService sharedInstance].clientId] == NO) {
        [NSException raise:NSInvalidArgumentException format:@"members should contain myself"];
    }
    [self checkDuplicateValueOfArray:members];
    [self createConversationWithMembers:members type:type unique:YES callback:callback];
}

- (void)createConversationWithMembers:(NSArray *)members type:(LCCKConversationType)type unique:(BOOL)unique callback:(AVIMConversationResultBlock)callback {
    NSString *name = nil;
    if (type == LCCKConversationTypeGroup) {
        // 群聊默认名字， 老王、小李
        name = [self groupConversaionDefaultNameForUserIds:members];
    }
    AVIMConversationOption options;
    if (unique) {
        // 如果相同 members 的对话已经存在，将返回原来的对话
        options = AVIMConversationOptionUnique;
    } else {
        // 创建一个新对话
        options = AVIMConversationOptionNone;
    }
    [self.client createConversationWithName:name clientIds:members attributes:@{ LCCK_CONVERSATION_TYPE : @(type) } options:options callback:callback];
}

- (NSString *)groupConversaionDefaultNameForUserIds:(NSArray *)userIds {
    NSError *error = nil;
    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:userIds];
    NSString *currentClientId = [LCChatKit sharedInstance].clientId;
    [mutableArray addObject:currentClientId];
    userIds = [mutableArray copy];
    NSArray<id<LCCKUserDelegate>> *array = [[LCCKUserSystemService sharedInstance] getCachedProfilesIfExists:userIds error:&error];
    if (error || (array.count == 0)) {
        NSString *groupName = [userIds componentsJoinedByString:@","];
        return groupName;
    }
    
    NSMutableArray *names = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id<LCCKUserDelegate>  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
        [names addObject:user.name ?: user.clientId];
    }];
    return [names componentsJoinedByString:@","];
}

- (NSString *)databasePathWithUserId:(NSString *)userId {
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *appId = [LCChatKit sharedInstance].appId;
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"com.leancloud.lcchatkit.%@.%@.db", appId, userId]];
}

- (void)setupDatabaseWithUserId:(NSString *)userId {
    NSString *dbPath = [self databasePathWithUserId:userId];
    [self setupSucceedMessageDatabaseWithPath:dbPath];
    [self setupFailedMessagesDBWithDatabasePath:dbPath];
}

- (void)setupSucceedMessageDatabaseWithPath:(NSString *)path {
    if (!self.databaseQueue) {
        //FIXME:when tom log out then jerry login , log this
        LCCKLog(@"database queue should not be nil !!!!");
    }
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversatoinTableCreateSQL];
    }];
}

- (void)updateConversationAsRead {
    AVIMConversation *conversation = self.currentConversation;
    NSString *conversationId = conversation.conversationId;
    if (!conversation.createAt || !conversation.imClient) {
        NSAssert(conversation.imClient, @"类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"imClient or conversation is nil");
        return;
    }
    [self insertRecentConversation:conversation shouldRefreshWhenFinished:NO];
    [self updateUnreadCountToZeroWithConversationId:conversationId shouldRefreshWhenFinished:NO];
    [self updateMentioned:NO conversationId:conversationId shouldRefreshWhenFinished:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
}

- (void)setCurrentConversation:(AVIMConversation *)currentConversation {
    _currentConversation = currentConversation;
    [self pinIMClientToConversationIfNeeded:currentConversation];
}

- (void)pinIMClientToConversationIfNeeded:(AVIMConversation *)conversation {
    if (!conversation.imClient) {
        [conversation setValue:[LCChatKit sharedInstance].client forKey:@"imClient"];
    }
}

- (AVIMConversation *)currentConversation {
    [self pinIMClientToConversationIfNeeded:_currentConversation];
    return _currentConversation;
}

- (BOOL)isChatting {
    return (self.currentConversationId.length > 0);
}

#pragma mark - conversations local data

- (NSData *)dataFromConversation:(AVIMConversation *)conversation {
    AVIMKeyedConversation *keydConversation = [conversation keyedConversation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keydConversation];
    return data;
}

- (AVIMConversation *)conversationFromData:(NSData *)data {
    AVIMKeyedConversation *keyedConversation = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    AVIMConversation *conversation = [[LCCKSessionService sharedInstance].client conversationWithKeyedConversation:keyedConversation];
    return conversation;
}

- (void)updateUnreadCountToZeroWithConversationId:(NSString *)conversationId {
    [self updateUnreadCountToZeroWithConversationId:conversationId shouldRefreshWhenFinished:YES];
}

- (void)updateUnreadCountToZeroWithConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableUpdateUnreadCountSQL  withArgumentsInArray:@[@0, conversationId]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}

- (void)deleteRecentConversationWithConversationId:(NSString *)conversationId {
    [self deleteRecentConversationWithConversationId:conversationId shouldRefreshWhenFinished:YES];
}

- (void)deleteRecentConversationWithConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableDeleteSQL withArgumentsInArray:@[conversationId]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}

- (void)insertRecentConversation:(AVIMConversation *)conversation {
    [self insertRecentConversation:conversation shouldRefreshWhenFinished:YES];
}

- (void)insertRecentConversation:(AVIMConversation *)conversation shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    if (!conversation.createAt) {
        return;
    }
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSData *data = [self dataFromConversation:conversation];
        [db executeUpdate:LCCKConversationTableInsertSQL withArgumentsInArray:@[conversation.conversationId, data, @0, @(NO), @""]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}

- (BOOL)isRecentConversationExistWithConversationId:(NSString *)conversationId {
    __block BOOL exists = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:LCCKConversationTableSelectOneSQL withArgumentsInArray:@[conversationId]];
        if ([resultSet next]) {
            exists = YES;
        }
        [resultSet close];
    }];
    return exists;
}

- (void)increaseUnreadCountWithConversationId:(NSString *)conversationId {
    [self increaseUnreadCountWithConversationId:conversationId shouldRefreshWhenFinished:YES];
}

- (void)increaseUnreadCountWithConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableIncreaseOneUnreadCountSQL withArgumentsInArray:@[conversationId]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}
- (void)increaseUnreadCount:(NSUInteger)increaseUnreadCount withConversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableIncreaseUnreadCountSQL withArgumentsInArray:@[@(increaseUnreadCount) ,conversationId]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}
- (void)updateMentioned:(BOOL)mentioned conversationId:(NSString *)conversationId {
    [self updateMentioned:mentioned conversationId:conversationId shouldRefreshWhenFinished:YES];
}

- (void)updateMentioned:(BOOL)mentioned conversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableUpdateMentionedSQL withArgumentsInArray:@[@(mentioned), conversationId]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}

- (NSString *)draftWithConversationId:(NSString *)conversationId {
    __block NSString *draft = nil;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
       FMResultSet *resultSet = [db executeQuery:LCCKConversationTableSelectDraftSQL withArgumentsInArray:@[conversationId]];
        if ([resultSet next]) {
            draft = [resultSet stringForColumn:LCCKConversationTableKeyDraft];
        }
        [resultSet close];
    }];
    return draft;
}

- (void)updateDraft:(NSString *)draft conversationId:(NSString *)conversationId {
    [self updateDraft:draft conversationId:conversationId shouldRefreshWhenFinished:YES];
}

- (void)updateDraft:(NSString *)draft conversationId:(NSString *)conversationId shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableUpdateDraftSQL withArgumentsInArray:@[draft ?: @"", conversationId]];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}

- (AVIMConversation *)createConversationFromResultSet:(FMResultSet *)resultSet {
    NSData *data = [resultSet dataForColumn:LCCKConversationTableKeyData];
    NSInteger unreadCount = [resultSet intForColumn:LCCKConversationTableKeyUnreadCount];
    BOOL mentioned = [resultSet boolForColumn:LCCKConversationTableKeyMentioned];
    NSString *draft = [resultSet stringForColumn:LCCKConversationTableKeyDraft];
    AVIMConversation *conversation = [self conversationFromData:data];
    conversation.lcck_unreadCount = unreadCount;
    conversation.lcck_mentioned = mentioned;
    conversation.lcck_draft = draft;
    [self pinIMClientToConversationIfNeeded:conversation];
    return conversation;
}

- (NSArray *)allRecentConversations {
    NSMutableArray *conversations = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet  *resultSet = [db executeQuery:LCCKConversationTableSelectSQL withArgumentsInArray:@[]];
        while ([resultSet next]) {
            AVIMConversation *conversation = [self createConversationFromResultSet:resultSet];
            BOOL isAvailable = conversation.createAt;
            if (isAvailable) {
                [conversations addObject:conversation];
            } 
        }
        [resultSet close];
    }];
    return conversations;
}

- (void)updateRecentConversation:(NSArray *)conversations {
    [self updateRecentConversation:conversations shouldRefreshWhenFinished:YES];
}

- (void)updateRecentConversation:(NSArray *)conversations shouldRefreshWhenFinished:(BOOL)shouldRefreshWhenFinished {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db beginTransaction];
        for (AVIMConversation *conversation in conversations) {
            [db executeUpdate:LCCKConversationTableUpdateDataSQL, [self dataFromConversation:conversation], conversation.conversationId];
        }
        [db commit];
    }];
    if (shouldRefreshWhenFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationListDataSourceUpdated object:self];
    }
}

/**
 *  删除对话对应的UIProfile缓存，比如当用户信息发生变化时
 *  @param  conversation 对话，可以是单聊，也可是群聊
 */
- (void)removeCacheForConversationId:(NSString *)conversationId {
    [self deleteRecentConversationWithConversationId:conversationId];
}

/**
 *  删除全部缓存，比如当切换用户时，如果同一个人显示的名称和头像需要变更
 */
- (BOOL)removeAllCachedRecentConversations {
    __block BOOL removeAllCachedRecentConversationsSuccess = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        removeAllCachedRecentConversationsSuccess = [db executeUpdate:LCCKDeleteConversationTable];
    }];
    return removeAllCachedRecentConversationsSuccess;
}

#pragma mark - FailedMessageStore
///=============================================================================
/// @name FailedMessageStore
///=============================================================================

/**
 *  openClient 时调用
 *  @param path 与 clientId 相关
 */
- (void)setupFailedMessagesDBWithDatabasePath:(NSString *)path {
    if (!self.databaseQueue) {
        LCCKLog(@"database queue should not be nil !!!!");
    }
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKCreateTableSQL];
    }];
}

- (NSDictionary *)recordFromResultSet:(FMResultSet *)resultSet {
    NSMutableDictionary *record = [NSMutableDictionary dictionary];
    NSData *data = [resultSet dataForColumn:LCCKKeyMessage];
    if (!data) {
        return nil;
    }
    id message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [record setObject:message forKey:LCCKKeyMessage];
    NSString *idValue = [resultSet stringForColumn:LCCKKeyId];
    [record setObject:idValue forKey:LCCKKeyId];
    return record;
}

- (NSArray *)recordsByConversationId:(NSString *)conversationId {
    NSMutableArray *records = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:LCCKSelectMessagesSQL, conversationId];
        while ([resultSet next]) {
            [records addObject:[self recordFromResultSet:resultSet]];
        }
        [resultSet close];
    }];
    return records;
}

- (NSArray *)failedMessagesByConversationId:(NSString *)conversationId {
    NSArray *records = [self recordsByConversationId:conversationId];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSDictionary *record in records) {
        [messages addObject:record[LCCKKeyMessage]];
    }
    return messages;
}

- (NSArray *)failedMessageIdsByConversationId:(NSString *)conversationId {
    NSArray *records = [self recordsByConversationId:conversationId];
    NSMutableArray *failedMessageIds = [NSMutableArray array];
    for (NSDictionary *record in records) {
        [failedMessageIds addObject:record[LCCKKeyId]];
    }
    return failedMessageIds;
}

- (NSArray *)recordsByMessageIds:(NSArray<NSString *> *)messageIds {
    NSString *messageIdsString = [messageIds componentsJoinedByString:@"','"];
    NSMutableArray *records = [NSMutableArray array];
    NSString *query = [NSString stringWithFormat:LCCKSelectMessagesByIDSQL, messageIdsString];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:query];
        while ([resultSet next]) {
            [records addObject:[self recordFromResultSet:resultSet]];
        }
        [resultSet close];
    }];
    
    return records;
}

- (NSArray *)failedMessagesByMessageIds:(NSArray *)messageIds {
    NSArray *records = [self recordsByMessageIds:messageIds];
    if (records.count == 0) {
        return nil;
    }
    NSMutableArray *messages = [NSMutableArray array];
    for (NSDictionary *record in records) {
        [messages addObject:record[LCCKKeyMessage]];
    }
    return messages;
}

- (BOOL)deleteFailedMessageByRecordId:(NSString *)recordId {
    __block BOOL result;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:LCCKDeleteMessageSQL, recordId];
    }];
    return result;
}

- (BOOL)deleteFile:(NSString *)pathOfFileToDelete error:(NSError **)error {
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:pathOfFileToDelete];
    if(exists) {
        [[NSFileManager defaultManager] removeItemAtPath:pathOfFileToDelete error:error];
    }
    return exists;
}

- (void)insertFailedLCCKMessage:(LCCKMessage *)message {
    if (message.conversationId == nil) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"conversationId is nil"
                                     userInfo:nil];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
    NSAssert(data, @"You can not insert nil message to DB");
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKInsertMessageSQL, message.localMessageId, message.conversationId, data];
    }];
}

- (void)insertFailedMessage:(AVIMTypedMessage *)message {
    if (message.conversationId == nil) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"conversationId is nil"
                                     userInfo:nil];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKInsertMessageSQL, message.messageId, message.conversationId, data];
    }];
}

#pragma mark - remote notification

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (userInfo[@"convid"]) {
        self.remoteNotificationConversationId = userInfo[@"convid"];
    }
}

#pragma mark - utils

- (void)sendMessage:(AVIMTypedMessage*)message
       conversation:(AVIMConversation *)conversation
      progressBlock:(AVProgressBlock)progressBlock
           callback:(LCCKBooleanResultBlock)block {
    [self sendMessage:message conversation:conversation options:AVIMMessageSendOptionNone progressBlock:progressBlock callback:block];
}

- (void)sendMessage:(AVIMTypedMessage*)message
       conversation:(AVIMConversation *)conversation
            options:(AVIMMessageSendOption)options
      progressBlock:(AVProgressBlock)progressBlock
           callback:(LCCKBooleanResultBlock)block  {
    id<LCCKUserDelegate> currentUser = [[LCCKUserSystemService sharedInstance] fetchCurrentUser];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    // 云代码中获取到用户名，来设置推送消息, 老王:今晚约吗？
    if (currentUser.name) {
        // 避免为空造成崩溃
        [attributes setObject:currentUser.name forKey:@"username"];
    }
    if ([LCCKSettingService sharedInstance].useDevPushCerticate) {
        [attributes setObject:@YES forKey:@"dev"];
    }
    if (message.attributes == nil) {
        message.attributes = attributes;
    } else {
        [attributes addEntriesFromDictionary:message.attributes];
        message.attributes = attributes;
    }
    [conversation sendMessage:message options:options progressBlock:progressBlock callback:block];
}

- (void)sendWelcomeMessageToPeerId:(NSString *)peerId text:(NSString *)text block:(LCCKBooleanResultBlock)block {
    [self fecthConversationWithPeerId:peerId callback:^(AVIMConversation *conversation, NSError *error) {
        if (error) {
            !block ?: block(NO, error);
        } else {
            AVIMTextMessage *textMessage = [AVIMTextMessage messageWithText:text attributes:nil];
            [self sendMessage:textMessage conversation:conversation progressBlock:nil callback:block];
        }
    }];
}

- (void)sendWelcomeMessageToConversationId:(NSString *)conversationId text:(NSString *)text block:(LCCKBooleanResultBlock)block {
    [self fecthConversationWithConversationId:conversationId callback:^(AVIMConversation *conversation, NSError *error) {
        if (error) {
            !block ?: block(NO, error);
        } else {
            AVIMTextMessage *textMessage = [AVIMTextMessage messageWithText:text attributes:nil];
            [self sendMessage:textMessage conversation:conversation progressBlock:nil callback:block];
        }
    }];
}

#pragma mark - query msgs

- (void)setFetchConversationHandler:(LCCKFetchConversationHandler)fetchConversationHandler {
    _fetchConversationHandler = fetchConversationHandler;
}

- (void)setConversationInvalidedHandler:(LCCKConversationInvalidedHandler)conversationInvalidedHandler {
    _conversationInvalidedHandler = conversationInvalidedHandler;
}

- (void)setLoadLatestMessagesHandler:(LCCKLoadLatestMessagesHandler)loadLatestMessagesHandler {
    _loadLatestMessagesHandler = loadLatestMessagesHandler;
}

- (void)queryTypedMessagesWithConversation:(AVIMConversation *)conversation
                                 timestamp:(int64_t)timestamp
                                     limit:(NSInteger)limit
                                     block:(AVIMArrayResultBlock)block {
    AVIMArrayResultBlock callback = ^(NSArray *messages, NSError *error) {
        if (!messages) {
            NSString *errorReason = [NSString stringWithFormat:@"类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"SDK处理异常，请联系SDK维护者修复luohanchenyilong@163.com"];
            NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), errorReason);
            // NSAssert(messages, errorReason);
        }
        //以下过滤为了避免非法的消息，引起崩溃，确保展示的只有 AVIMTypedMessage 类型
        NSMutableArray *typedMessages = [NSMutableArray array];
        for (AVIMTypedMessage *message in messages) {
            [typedMessages addObject:[message lcck_getValidTypedMessage]];
        }
        !block ?: block(typedMessages, error);
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if(timestamp == 0) {
            // 该方法能确保在有网络时总是从服务端拉取最新的消息，首次拉取必须使用该方法
            // sdk 会设置好 timestamp
            [conversation queryMessagesWithLimit:limit callback:callback];
        } else {
            //会先根据本地缓存判断是否有必要从服务端拉取，这个方法不能用于首次拉取
            [conversation queryMessagesBeforeId:nil timestamp:timestamp limit:limit callback:callback];
        }
    });
}

+ (void)cacheFileTypeMessages:(NSArray<AVIMTypedMessage *> *)messages callback:(AVBooleanResultBlock)callback {
    NSMutableSet *userIds = [[NSMutableSet alloc] init];
    NSString *queueBaseLabel = [NSString stringWithFormat:@"com.chatkit.%@", NSStringFromClass([self class])];
    const char *queueName = [[NSString stringWithFormat:@"%@.ForBarrier",queueBaseLabel] UTF8String];
    dispatch_queue_t queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_CONCURRENT);
    
    for (AVIMTypedMessage *message in messages) {
        dispatch_async(queue, ^(void) {
            if (message.mediaType == kAVIMMessageMediaTypeImage || message.mediaType == kAVIMMessageMediaTypeAudio) {
                AVFile *file = message.file;
                if (file && file.isDataAvailable == NO) {
                    NSError *error;
                    // 下载到本地
                    NSData *data = [file getData:&error];
                    if (error || data == nil) {
                        LCCKLog(@"download file error : %@", error);
                    }
                }
            } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
                NSString *path = [[LCCKSettingService sharedInstance] videoPathOfMessage:(AVIMVideoMessage *)message];
                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSError *error;
                    NSData *data = [message.file getData:&error];
                    if (error) {
                        LCCKLog(@"download file error : %@", error);
                    } else {
                        [data writeToFile:path atomically:YES];
                    }
                }
            }
        });
    }
    dispatch_barrier_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(),^{
            !callback ?: callback(YES, nil);
        });
    });
}

- (AVIMClient *)client {
    if (!_client) {
        AVIMClient *client = [LCCKSessionService sharedInstance].client;
        _client = client;
    }
    return _client;
}

@end
