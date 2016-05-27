//
//  LCCKConversationService.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKConversationService.h"
#import "LCChatKit.h"
#if __has_include(<FMDB/FMDB.h>)
#import <FMDB/FMDB.h>
#else
#import "FMDB.h"
#endif

#import "AVIMConversation+LCCKAddition.h"
#import "LCCKConversationViewController.h"
#import "LCCKConversationListViewController.h"
#import "LCCKMessage.h"
#import "LCCKConversationListService.h"

NSString *const LCCKConversationServiceErrorDomain = @"LCCKConversationServiceErrorDomain";

@interface LCCKConversationService()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) AVIMClient *client;

@end

@implementation LCCKConversationService

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
    [[LCCKConversationListService sharedInstance] fetchConversationsWithConversationIds:conversationSet callback:^(NSArray *objects, NSError *error) {
        if (error) {
            !callback ?: callback(nil, error);
        } else {
            if (objects.count == 0) {
                NSString *errorReasonText = [NSString stringWithFormat:@"conversation of %@ are not exists", conversationId];
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
                !callback ?: callback(objects[0], error);
            }
        }
    }];
}

- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback {
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
    NSArray *array = [[LCCKUserSystemService sharedInstance] getProfilesForUserIds:userIds error:&error];
    if (error) {
        return nil;
    }
    
    NSMutableArray *names = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id<LCCKUserModelDelegate>  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
        [names addObject:user.name];
    }];
    return [names componentsJoinedByString:@","];
}

- (NSString *)databasePathWithUserId:(NSString *)userId{
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"com.leancloud.lcchatkit.%@.db3", userId]];
}

- (void)setupDatabaseWithUserId:(NSString *)userId {
    NSString *dbPath = [self databasePathWithUserId:userId];
    [[LCCKConversationService sharedInstance] setupSucceedMessageDatabaseWithPath:dbPath];
    [[LCCKConversationService sharedInstance] setupFailedMessagesDBWithDatabasePath:dbPath];
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
    AVIMConversation *conversation = [LCCKConversationService sharedInstance].currentConversation;
    if (!conversation) {
        NSAssert(conversation, @"currentConversation is nil");
        return;
    }
    [[LCCKConversationService sharedInstance] insertRecentConversation:conversation];
    [[LCCKConversationService sharedInstance] updateUnreadCountToZeroWithConversation:conversation];
    [[LCCKConversationService sharedInstance] updateMentioned:NO conversation:conversation];
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
}

#pragma mark - conversations local data

- (NSData *)dataFromConversation:(AVIMConversation *)conversation {
    AVIMKeyedConversation *keydConversation = [conversation keyedConversation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keydConversation];
    return data;
}

- (AVIMConversation *)conversationFromData:(NSData *)data{

    AVIMKeyedConversation *keyedConversation = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return [[LCCKSessionService sharedInstance].client conversationWithKeyedConversation:keyedConversation];
}

- (void)updateUnreadCountToZeroWithConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableUpdateUnreadCountSQL  withArgumentsInArray:@[@0, conversation.conversationId]];
    }];
}

- (void)deleteRecentConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableDeleteSQL withArgumentsInArray:@[conversation.conversationId]];
    }];
}

- (void)insertRecentConversation:(AVIMConversation *)conversation {
    if (conversation.creator == nil) {
        return;
    }
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSData *data = [self dataFromConversation:conversation];
        [db executeUpdate:LCCKConversationTableInsertSQL withArgumentsInArray:@[conversation.conversationId, data, @0, @(NO)]];
    }];
}

- (BOOL)isRecentConversationExist:(AVIMConversation *)conversation {
    __block BOOL exists = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:LCCKConversationTableSelectOneSQL withArgumentsInArray:@[conversation.conversationId]];
        if ([resultSet next]) {
            exists = YES;
        }
        [resultSet close];
    }];
    return exists;
}

- (void)increaseUnreadCountWithConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableIncreaseUnreadCountSQL withArgumentsInArray:@[conversation.conversationId]];
    }];
}

- (void)updateMentioned:(BOOL)mentioned conversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCCKConversationTableUpdateMentionedSQL withArgumentsInArray:@[@(mentioned), conversation.conversationId]];
    }];
}

- (AVIMConversation *)createConversationFromResultSet:(FMResultSet *)resultSet {
    NSData *data = [resultSet dataForColumn:LCCKConversationTableKeyData];
    NSInteger unreadCount = [resultSet intForColumn:LCCKConversationTableKeyUnreadCount];
    BOOL mentioned = [resultSet boolForColumn:LCCKConversationTableKeyMentioned];
    AVIMConversation *conversation = [self conversationFromData:data];
    conversation.lcck_unreadCount = unreadCount;
    conversation.lcck_mentioned = mentioned;
    return conversation;
}

- (NSArray *)allRecentConversations {
    NSMutableArray *conversations = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet  *resultSet = [db executeQuery:LCCKConversationTableSelectSQL withArgumentsInArray:@[]];
        while ([resultSet next]) {
            [conversations addObject:[self createConversationFromResultSet:resultSet]];
        }
        [resultSet close];
    }];
    return conversations;
}

- (void)updateRecentConversation:(NSArray *)conversations {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db beginTransaction];
        for (AVIMConversation *conversation in conversations) {
            [db executeUpdate:LCCKConversationTableUpdateDataSQL, [self dataFromConversation:conversation], conversation.conversationId];
        }
        [db commit];
    }];
}

/**
 *  删除会话对应的UIProfile缓存，比如当用户信息发生变化时
 *  @param  conversation 会话，可以是单聊，也可是群聊
 */
- (void)removeCacheForConversation:(AVIMConversation *)conversation {
 //TODO:
    [self deleteRecentConversation:conversation];
    
}

/**
 *  删除全部缓存，比如当切换用户时，如果同一个人显示的名称和头像需要变更
 */
- (void)removeAllCachedRecentConversations {
    //TODO:
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
//        [db executeUpdate:LCCKDeleteConversationTable];
    }];
}

///----------------------------------------------------------------------
///---------------------FailedMessageStore-------------------------------
///----------------------------------------------------------------------

/**
 *  openClient 时调用
 *  @param path 与 clientId 相关
 */
- (void)setupFailedMessagesDBWithDatabasePath:(NSString *)path {
    if (!self.databaseQueue) {
        //FIXME:when tom log out then jerry login , log this
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
    AVIMTypedMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
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

- (BOOL)deleteFailedMessageByRecordId:(NSString *)recordId {
    __block BOOL result;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:LCCKDeleteMessageSQL, recordId];
    }];
    return result;
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
        [db executeUpdate:LCCKInsertMessageSQL, message.messageId, message.conversationId, data];
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
    id<LCCKUserModelDelegate> currentUser = [[LCCKUserSystemService sharedInstance] fetchCurrentUser];
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
    [conversation sendMessage:message options:AVIMMessageSendOptionRequestReceipt progressBlock:progressBlock callback:block];
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

#pragma mark - query msgs

- (void)queryTypedMessagesWithConversation:(AVIMConversation *)conversation timestamp:(int64_t)timestamp limit:(NSInteger)limit block:(AVIMArrayResultBlock)block {
    AVIMArrayResultBlock callback = ^(NSArray *messages, NSError *error) {
        //以下过滤为了避免非法的消息，引起崩溃
        NSMutableArray *typedMessages = [NSMutableArray array];
        for (AVIMTypedMessage *message in messages) {
            if ([message isKindOfClass:[AVIMTypedMessage class]]) {
                [typedMessages addObject:message];
            }
        }
        !block ?: block(typedMessages, error);
    };
    if(timestamp == 0) {
        // sdk 会设置好 timestamp
        [conversation queryMessagesWithLimit:limit callback:callback];
    } else {
        [conversation queryMessagesBeforeId:nil timestamp:timestamp limit:limit callback:callback];
    }
}

+ (void)cacheMessages:(NSArray<AVIMTypedMessage *> *)messages callback:(AVBooleanResultBlock)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableSet *userIds = [[NSMutableSet alloc] init];
        for (AVIMTypedMessage *message in messages) {
            [userIds addObject:message.clientId];
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
        }
        
        [[LCCKUserSystemService sharedInstance] cacheUsersWithIds:userIds callback:^(BOOL succeeded, NSError *error) {
            dispatch_async(dispatch_get_main_queue(),^{
                !callback ?: callback(succeeded, error);
            });
        }];
    });
}

- (AVIMClient *)client {
    _client = [LCCKSessionService sharedInstance].client;
    return _client;
}

@end
