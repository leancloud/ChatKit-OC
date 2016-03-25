//
//  LCIMConversationService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMConversationService.h"
#import "LCIMKit.h"
#import <FMDB/FMDB.h>
#import "AVIMConversation+LCIMAddition.h"
#import "LCIMConversationViewController.h"
#import "LCIMConversationListViewController.h"
#import "LCIMMessage.h"
#import "LCIMConversationListService.h"

///-------------------------------------------------------------------------
///---------------------Succeed Message Store-------------------------------
///-------------------------------------------------------------------------

#define LCIMConversationTableName           @"conversations"
#define LCIMConversationTableKeyId          @"id"
#define LCIMConversationTableKeyData        @"data"
#define LCIMConversationTableKeyUnreadCount @"unreadCount"
#define LCIMConversationTableKeyMentioned   @"mentioned"


#define LCIMConversatoinTableCreateSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " LCIMConversationTableName @" ("           \
        LCIMConversationTableKeyId           @" VARCHAR(63) PRIMARY KEY, "   \
        LCIMConversationTableKeyData         @" BLOB NOT NULL, "             \
        LCIMConversationTableKeyUnreadCount  @" INTEGER DEFAULT 0, "         \
        LCIMConversationTableKeyMentioned    @" BOOL DEFAULT FALSE "         \
    @")"

#define LCIMConversationTableInsertSQL                           \
    @"INSERT OR IGNORE INTO " LCIMConversationTableName @" ("    \
        LCIMConversationTableKeyId               @", "           \
        LCIMConversationTableKeyData             @", "           \
        LCIMConversationTableKeyUnreadCount      @", "           \
        LCIMConversationTableKeyMentioned                        \
    @") VALUES(?, ?, ?, ?)"

#define LCIMConversationTableWhereClause                         \
    @" WHERE " LCIMConversationTableKeyId         @" = ?"

#define LCIMConversationTableDeleteSQL                           \
    @"DELETE FROM " LCIMConversationTableName                    \
    LCIMConversationTableWhereClause

#define LCIMConversationTableIncreaseUnreadCountSQL              \
    @"UPDATE " LCIMConversationTableName         @" "            \
    @"SET " LCIMConversationTableKeyUnreadCount  @" = "          \
            LCIMConversationTableKeyUnreadCount  @" + 1 "        \
    LCIMConversationTableWhereClause

#define LCIMConversationTableUpdateUnreadCountSQL                \
    @"UPDATE " LCIMConversationTableName         @" "            \
    @"SET " LCIMConversationTableKeyUnreadCount  @" = ? "        \
    LCIMConversationTableWhereClause

#define LCIMConversationTableUpdateMentionedSQL                  \
    @"UPDATE " LCIMConversationTableName         @" "            \
    @"SET " LCIMConversationTableKeyMentioned    @" = ? "        \
    LCIMConversationTableWhereClause

#define LCIMConversationTableSelectSQL                           \
    @"SELECT * FROM " LCIMConversationTableName                  \

#define LCIMConversationTableSelectOneSQL                        \
    @"SELECT * FROM " LCIMConversationTableName                  \
    LCIMConversationTableWhereClause

#define LCIMConversationTableUpdateDataSQL                       \
    @"UPDATE " LCIMConversationTableName @" "                    \
    @"SET " LCIMConversationTableKeyData @" = ? "                \
    LCIMConversationTableWhereClause                             \

///------------------------------------------------------------------------
///---------------------Failed Message Store-------------------------------
///------------------------------------------------------------------------

#define LCIMFaildMessageTable   @"failed_messages"
#define LCIMKeyId               @"id"
#define LCIMKeyConversationId   @"conversationId"
#define LCIMKeyMessage          @"message"

#define LCIMCreateTableSQL                                       \
    @"CREATE TABLE IF NOT EXISTS " LCIMFaildMessageTable @"("    \
        LCIMKeyId @" VARCHAR(63) PRIMARY KEY, "                  \
        LCIMKeyConversationId @" VARCHAR(63) NOT NULL,"          \
        LCIMKeyMessage @" BLOB NOT NULL"                         \
    @")"

#define LCIMWhereConversationId \
    @" WHERE " LCIMKeyConversationId @" = ? "

#define LCIMSelectMessagesSQL                        \
    @"SELECT * FROM " LCIMFaildMessageTable          \
    LCIMWhereConversationId

#define LCIMInsertMessageSQL                             \
    @"INSERT OR IGNORE INTO " LCIMFaildMessageTable @"(" \
        LCIMKeyId @","                                   \
        LCIMKeyConversationId @","                       \
        LCIMKeyMessage                                   \
    @") values (?, ?, ?) "                              \

#define LCIMDeleteMessageSQL                             \
    @"DELETE FROM " LCIMFaildMessageTable @" "           \
    @"WHERE " LCIMKeyId " = ? "                          \
    
NSString *const LCIMConversationServiceErrorDomain = @"LCIMConversationServiceErrorDomain";

@interface LCIMConversationService()

@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong) AVIMClient *client;

@end

@implementation LCIMConversationService

/**
 * create a singleton instance of LCIMConversationService
 */
+ (instancetype)sharedInstance {
    static LCIMConversationService *_sharedLCIMConversationService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMConversationService = [[self alloc] init];
    });
    return _sharedLCIMConversationService;
}

- (AVIMConversation *)fetchConversationByConversationId:(NSString *)conversationId {
    //TODO:
    return nil;
}

/**
 *  根据 conversationId 获取对话
 *  @param convid   对话的 id
 *  @param callback
 */
- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(LCIMConversationResultBlock)callback {
    NSAssert(conversationId.length > 0, @"Conversation id is nil");
    AVIMConversation *conversation = [self.client conversationForId:conversationId];
    if (conversation) {
        !callback ?: callback(conversation, nil);
        return;
    }
    
    NSSet *conversationSet = [NSSet setWithObject:conversationId];
    [[LCIMConversationListService sharedInstance] fetchConversationsWithConversationIds:conversationSet callback:^(NSArray *objects, NSError *error) {
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
                NSError *error = [NSError errorWithDomain:LCIMConversationServiceErrorDomain
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
    if ([peerId isEqualToString:[[LCIMSessionService sharedInstance] clientId]]) {
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
    //TODO:unique ，这个怎么理解。是指的创建memberId 创建的会话都是unique的吗？
    //这里需要说明我们是怎么创建／reuse 的 conversation。
    //unique bool 可选，是否创建唯一会话。如果是创建唯一会话，会查询相同 m 的会话是否已经创建过，如果已经创建过就返回这个已创建的会话
    //是的。其实如果指定了 memberId，开发者关心的是：我第一次指定 peer 进入聊天，和第二次指定 peer 进入聊天，是否会是同一个对话——就是说历史消息还在不在？所以我们在注释里面要说明，我们是怎么根据 memberId 创建对话的。
    // unique 指的是这里的吧--》https://github.com/leancloud/avoscloud-push/blob/develop/push-server/doc/protocol.md#convstart
    
    NSString *myId = [LCIMSessionService sharedInstance].clientId;
    NSArray *array = @[ myId, peerId ];
    [self fetchConversationWithMembers:array type:LCIMConversationTypeSingle callback:callback];
}

- (void)checkDuplicateValueOfArray:(NSArray *)array {
    NSSet *set = [NSSet setWithArray:array];
    if (set.count != array.count) {
        [NSException raise:NSInvalidArgumentException format:@"The array has duplicate value"];
    }
}

- (void)fetchConversationWithMembers:(NSArray *)members type:(LCIMConversationType)type callback:(AVIMConversationResultBlock)callback {
    if ([members containsObject:[LCIMSessionService sharedInstance].clientId] == NO) {
        [NSException raise:NSInvalidArgumentException format:@"members should contain myself"];
    }
    [self checkDuplicateValueOfArray:members];
    [self createConversationWithMembers:members type:type unique:YES callback:callback];
}

- (void)createConversationWithMembers:(NSArray *)members type:(LCIMConversationType)type unique:(BOOL)unique callback:(AVIMConversationResultBlock)callback {
    NSString *name = nil;
    if (type == LCIMConversationTypeGroup) {
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
    [self.client createConversationWithName:name clientIds:members attributes:@{ LCIM_CONVERSATION_TYPE : @(type) } options:options callback:callback];
}

- (NSString *)groupConversaionDefaultNameForUserIds:(NSArray *)userIds {
    NSError *error = nil;
    NSArray *array = [[LCIMUserSystemService sharedInstance] getProfilesForUserIds:userIds error:&error];
    if (error) {
        return nil;
    }
    
    NSMutableArray *names = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id<LCIMUserModelDelegate>  _Nonnull user, NSUInteger idx, BOOL * _Nonnull stop) {
        [names addObject:user.name];
    }];
    return [names componentsJoinedByString:@","];
}

- (LCIMConversationViewController *)createConversationViewControllerWithConversationId:(NSString *)conversationId {
    LCIMConversationViewController *conversationViewController = [[LCIMConversationViewController alloc] initWithConversationId:conversationId];
    return conversationViewController;
}

- (LCIMConversationListViewController *)createConversationListViewController {
    LCIMConversationListViewController *conversationListViewController = [[LCIMConversationListViewController alloc] init];
    return conversationListViewController;
}

/**
 *  构建单聊页面
 *  @param aPerson 聊天对象
 */
- (LCIMConversationViewController *)createConversationViewControllerWithPeerId:(NSString *)peerId {
    LCIMConversationViewController *conversationViewController = [[LCIMConversationViewController alloc] initWithPeerId:peerId];
    return conversationViewController;
}

- (NSString *)databasePathWithUserId:(NSString *)userId{
    NSString *libPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [libPath stringByAppendingPathComponent:[NSString stringWithFormat:@"com.leancloud.lcimkit.%@.db3", userId]];
}

- (void)setupDatabaseWithUserId:(NSString *)userId {
    NSString *dbPath = [self databasePathWithUserId:userId];
    [[LCIMConversationService sharedInstance] setupSucceedMessageDatabaseWithPath:dbPath];
    [[LCIMConversationService sharedInstance] setupFailedMessagesDBWithDatabasePath:dbPath];
}

- (void)setupSucceedMessageDatabaseWithPath:(NSString *)path {
    if (self.databaseQueue) {
        DLog(@"database queue should not be nil !!!!");
    }
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMConversatoinTableCreateSQL];
    }];
}

#pragma mark - conversations local data

- (NSData *)dataFromConversation:(AVIMConversation *)conversation {
    AVIMKeyedConversation *keydConversation = [conversation keyedConversation];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:keydConversation];
    return data;
}

- (AVIMConversation *)conversationFromData:(NSData *)data{
    AVIMKeyedConversation *keyedConversation = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return [[LCIMSessionService sharedInstance].client conversationWithKeyedConversation:keyedConversation];
}

- (void)updateUnreadCountToZeroWithConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMConversationTableUpdateUnreadCountSQL  withArgumentsInArray:@[@0 , conversation.conversationId]];
    }];
}

- (void)deleteConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMConversationTableDeleteSQL withArgumentsInArray:@[conversation.conversationId]];
    }];
}

- (void )insertConversation:(AVIMConversation *)conversation {
    if (conversation.creator == nil) {
        return;
    }
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        NSData *data = [self dataFromConversation:conversation];
        [db executeUpdate:LCIMConversationTableInsertSQL withArgumentsInArray:@[conversation.conversationId, data, @0, @(NO)]];
    }];
}

- (BOOL)isConversationExists:(AVIMConversation *)conversation {
    __block BOOL exists = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:LCIMConversationTableSelectOneSQL withArgumentsInArray:@[conversation.conversationId]];
        if ([resultSet next]) {
            exists = YES;
        }
        [resultSet close];
    }];
    return exists;
}

- (void)increaseUnreadCountWithConversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMConversationTableIncreaseUnreadCountSQL withArgumentsInArray:@[conversation.conversationId]];
    }];
}

- (void)updateMentioned:(BOOL)mentioned conversation:(AVIMConversation *)conversation {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMConversationTableUpdateMentionedSQL withArgumentsInArray:@[@(mentioned), conversation.conversationId]];
    }];
}

- (AVIMConversation *)createConversationFromResultSet:(FMResultSet *)resultSet {
    NSData *data = [resultSet dataForColumn:LCIMConversationTableKeyData];
    NSInteger unreadCount = [resultSet intForColumn:LCIMConversationTableKeyUnreadCount];
    BOOL mentioned = [resultSet boolForColumn:LCIMConversationTableKeyMentioned];
    AVIMConversation *conversation = [self conversationFromData:data];
    conversation.lcim_unreadCount = unreadCount;
    conversation.lcim_mentioned = mentioned;
    return conversation;
}

- (NSArray *)selectAllConversations {
    NSMutableArray *conversations = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet  *resultSet = [db executeQuery:LCIMConversationTableSelectSQL withArgumentsInArray:@[]];
        while ([resultSet next]) {
            [conversations addObject:[self createConversationFromResultSet:resultSet]];
        }
        [resultSet close];
    }];
    return conversations;
}

- (void)updateConversations:(NSArray *)conversations {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db beginTransaction];
        for (AVIMConversation *conversation in conversations) {
            [db executeUpdate:LCIMConversationTableUpdateDataSQL, [self dataFromConversation:conversation], conversation.conversationId];
        }
        [db commit];
    }];
}

///---------------------------------------------------------------------
///---------------------FailedMessageStore-------------------------------
///---------------------------------------------------------------------

/**
 *  openClient 时调用
 *  @param path 与 clientId 相关
 */
- (void)setupFailedMessagesDBWithDatabasePath:(NSString *)path {
    if (self.databaseQueue) {
        DLog(@"database queue should not be nil !!!!");
    }
    self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMCreateTableSQL];
    }];
}

- (NSDictionary *)recordFromResultSet:(FMResultSet *)resultSet {
    NSMutableDictionary *record = [NSMutableDictionary dictionary];
    NSData *data = [resultSet dataForColumn:LCIMKeyMessage];
    AVIMTypedMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [record setObject:message forKey:LCIMKeyMessage];
    NSString *idValue = [resultSet stringForColumn:LCIMKeyId];
    [record setObject:idValue forKey:LCIMKeyId];
    return record;
}

- (NSArray *)recordsByConversationId:(NSString *)conversationId {
    NSMutableArray *records = [NSMutableArray array];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:LCIMSelectMessagesSQL, conversationId];
        while ([resultSet next]) {
            [records addObject:[self recordFromResultSet:resultSet]];
        }
        [resultSet close];
    }];
    return records;
}

- (NSArray *)selectFailedMessagesByConversationId:(NSString *)conversationId {
    NSArray *records = [self recordsByConversationId:conversationId];
    NSMutableArray *messages = [NSMutableArray array];
    for (NSDictionary *record in records) {
        [messages addObject:record[LCIMKeyMessage]];
    }
    return messages;
}

- (BOOL)deleteFailedMessageByRecordId:(NSString *)recordId {
    __block BOOL result;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:LCIMDeleteMessageSQL, recordId];
    }];
    return result;
}

- (void)insertFailedLCIMMessage:(LCIMMessage *)message {
    if (message.conversationId == nil) {
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:@"conversationId is nil"
                                     userInfo:nil];
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
    NSAssert(data, @"You can not insert nil message to DB");
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:LCIMInsertMessageSQL, message.messageId, message.conversationId, data];
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
        [db executeUpdate:LCIMInsertMessageSQL, message.messageId, message.conversationId, data];
    }];
}

#pragma mark - remote notification

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (userInfo[@"convid"]) {
        self.remoteNotificationConversationId = userInfo[@"convid"];
    }
}

#pragma mark - utils

- (void)sendMessage:(AVIMTypedMessage*)message conversation:(AVIMConversation *)conversation callback:(LCIMBooleanResultBlock)block {
    id<LCIMUserModelDelegate> currentUser = [[LCIMUserSystemService sharedInstance] fetchCurrentUser];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    // 云代码中获取到用户名，来设置推送消息, 老王:今晚约吗？
    if (currentUser.name) {
        // 避免为空造成崩溃
        [attributes setObject:currentUser.name forKey:@"username"];
    }
    if ([LCIMSettingService sharedInstance].useDevPushCerticate) {
        [attributes setObject:@YES forKey:@"dev"];
    }
    if (message.attributes == nil) {
        message.attributes = attributes;
    } else {
        [attributes addEntriesFromDictionary:message.attributes];
        message.attributes = attributes;
    }
    [conversation sendMessage:message options:AVIMMessageSendOptionRequestReceipt callback:block];
}

- (void)sendWelcomeMessageToPeerId:(NSString *)peerId text:(NSString *)text block:(LCIMBooleanResultBlock)block {
    [self fecthConversationWithPeerId:peerId callback:^(AVIMConversation *conversation, NSError *error) {
        if (error) {
            !block ?: block(NO, error);
        } else {
            AVIMTextMessage *textMessage = [AVIMTextMessage messageWithText:text attributes:nil];
            [self sendMessage:textMessage conversation:conversation callback:block];
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



- (void)openChatWithPeerId:(NSString *)peerId fromController:(UIViewController *)controller {
//    id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
//    UIWindow *window = delegate.window;
//    UITabBarController *tabBarController = (UITabBarController *)window.rootViewController;
//    UINavigationController *navigationController = tabBarController.selectedViewController;
//   __block LCIMConversationViewController *conversationViewController;
//    
//    [self fecthConversationWithPeerId:peerId callback:^(AVIMConversation *conversation, NSError *error) {
//        if (!error) {
//            conversationViewController = [[LCIMConversationViewController alloc] initWithConversation:conversation];
//            if (conversationViewController) {
//                dispatch_async(dispatch_get_main_queue(),^{
//                    [navigationController pushViewController:conversationViewController animated:YES];
//                });
//            }
//        }
//    }];

//    if (conversationViewController) {
//        return YES;
//    }
//    return NO;
}

/**
 *  lazy load client
 *
 *  @return AVIMClient
 */
- (AVIMClient *)client {
    if (_client == nil) {
        _client = [[LCIMSessionService sharedInstance] client];
    }
    return _client;
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
                        DLog(@"download file error : %@", error);
                    }
                }
            } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
                NSString *path = [[LCIMSettingService sharedInstance] videoPathOfMessage:(AVIMVideoMessage *)message];
                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSError *error;
                    NSData *data = [message.file getData:&error];
                    if (error) {
                        DLog(@"download file error : %@", error);
                    } else {
                        [data writeToFile:path atomically:YES];
                    }
                }
            }
        }
        
        [[LCIMUserSystemService sharedInstance] cacheUsersWithIds:userIds callback:^(BOOL succeeded, NSError *error) {
            dispatch_async(dispatch_get_main_queue(),^{
                !callback ?: callback(succeeded, error);
            });
        }];
    });
}

@end
