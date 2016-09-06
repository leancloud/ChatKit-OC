//
//  LCIMMessageCacheStore.m
//  AVOS
//
//  Created by Tang Tianyong on 5/21/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCIMMessageCacheStore.h"
#import "LCIMMessageCacheStoreSQL.h"
#import "AVIMMessage.h"
#import "AVIMMessage_Internal.h"
#import "AVIMTypedMessage.h"
#import "AVIMTypedMessage_Internal.h"
#import "LCDatabaseMigrator.h"

@interface LCIMMessageCacheStore ()

@property (copy, readwrite) NSString *conversationId;

@end

@implementation LCIMMessageCacheStore

- (void)databaseQueueDidLoad {
    [self.databaseQueue inDatabase:^(LCDatabase *db) {
        db.logsErrors = LCIM_SHOULD_LOG_ERRORS;

        [db executeUpdate:LCIM_SQL_CREATE_MESSAGE_TABLE];
        [db executeUpdate:LCIM_SQL_CREATE_MESSAGE_UNIQUE_INDEX];
    }];

    [self migrateDatabaseIfNeeded:self.databaseQueue.path];
}

- (void)migrateDatabaseIfNeeded:(NSString *)databasePath {
    LCDatabaseMigrator *migrator = [[LCDatabaseMigrator alloc] initWithDatabasePath:databasePath];

    [migrator executeMigrations:@[
        // Migrations of each database version
    ]];
}

- (instancetype)initWithClientId:(NSString *)clientId conversationId:(NSString *)conversationId {
    self = [super initWithClientId:clientId];

    if (self) {
        _conversationId = [conversationId copy];
    }

    return self;
}

- (NSNumber *)timestampForMessage:(AVIMMessage *)message {
    NSTimeInterval ts = message.sendTimestamp ?: [self currentTimestamp];
    return [NSNumber numberWithDouble:ts];
}

- (NSNumber *)receiptTimestampForMessage:(AVIMMessage *)message {
    return [NSNumber numberWithDouble:message.deliveredTimestamp];
}

- (NSTimeInterval)currentTimestamp {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

- (NSArray *)updationRecordForMessage:(AVIMMessage *)message {
    return @[
        message.clientId,
        [self timestampForMessage:message],
        [self receiptTimestampForMessage:message],
        [message.payload dataUsingEncoding:NSUTF8StringEncoding],
        @(message.status),
        self.conversationId,
        message.messageId
    ];
}

- (NSArray *)insertionRecordForMessage:(AVIMMessage *)message {
    return @[
        message.messageId,
        self.conversationId,
        message.clientId,
        [self timestampForMessage:message],
        [self receiptTimestampForMessage:message],
        [message.payload dataUsingEncoding:NSUTF8StringEncoding],
        @(message.status),
        @(NO)
    ];
}

- (NSArray *)insertionRecordForMessage:(AVIMMessage *)message withBreakpoint:(BOOL)breakpoint {
    return @[
        message.messageId,
        self.conversationId,
        message.clientId,
        [self timestampForMessage:message],
        [self receiptTimestampForMessage:message],
        [message.payload dataUsingEncoding:NSUTF8StringEncoding],
        @(message.status),
        @(breakpoint)
    ];
}

- (void)insertMessages:(NSArray *)messages {
    LCIM_OPEN_DATABASE(db, ({
        for (AVIMMessage *message in messages) {
            NSArray *args = [self insertionRecordForMessage:message];
            [db executeUpdate:LCIM_SQL_INSERT_MESSAGE withArgumentsInArray:args];
        }
    }));
}

- (void)insertMessage:(AVIMMessage *)message {
    [self insertMessages:@[message]];
}

- (void)insertMessage:(AVIMMessage *)message withBreakpoint:(BOOL)breakpoint {
    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = [self insertionRecordForMessage:message withBreakpoint:breakpoint];
        [db executeUpdate:LCIM_SQL_INSERT_MESSAGE withArgumentsInArray:args];
    }));
}

- (void)updateBreakpoint:(BOOL)breakpoint forMessages:(NSArray *)messages {
    LCIM_OPEN_DATABASE(db, ({
        for (AVIMMessage *message in messages) {
            NSArray *args = @[
                @(breakpoint),
                self.conversationId,
                message.messageId
            ];

            [db executeUpdate:LCIM_SQL_UPDATE_MESSAGE_BREAKPOINT withArgumentsInArray:args];
        }
    }));
}

- (void)updateBreakpoint:(BOOL)breakpoint forMessage:(AVIMMessage *)message {
    [self updateBreakpoint:breakpoint forMessages:@[message]];
}

- (void)updateMessageWithoutBreakpoint:(AVIMMessage *)message {
    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = [self updationRecordForMessage:message];
        [db executeUpdate:LCIM_SQL_UPDATE_MESSAGE withArgumentsInArray:args];
    }));
}

- (void)deleteMessageForId:(NSString *)messageId {
    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = @[self.conversationId, messageId];
        [db executeUpdate:LCIM_SQL_DELETE_MESSAGE withArgumentsInArray:args];
    }));
}

- (BOOL)containMessage:(AVIMMessage *)message {
    return [self messageForId:message.messageId] != nil;
}

- (NSArray *)messagesBeforeTimestamp:(int64_t)timestamp
                           messageId:(NSString *)messageId
                               limit:(NSUInteger)limit
{
    NSMutableArray *messages = [NSMutableArray array];

    LCIM_OPEN_DATABASE(db, ({
        LCResultSet *result = nil;

        if (messageId) {
            NSArray *args = @[self.conversationId, @(timestamp), @(timestamp), messageId, @(limit)];
            result = [db executeQuery:LCIM_SQL_SELECT_MESSAGE_LESS_THAN_TIMESTAMP_AND_ID withArgumentsInArray:args];
        } else {
            NSArray *args = @[self.conversationId, @(timestamp), @(limit)];
            result = [db executeQuery:LCIM_SQL_SELECT_MESSAGE_LESS_THAN_TIMESTAMP withArgumentsInArray:args];
        }

        while ([result next]) {
            [messages insertObject:[self messageForRecord:result] atIndex:0];
        }

        [result close];
    }));

    return messages;
}

- (AVIMMessage *)messageForId:(NSString *)messageId {
    if (!messageId) return nil;

    __block AVIMMessage *message = nil;

    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = @[self.conversationId, messageId];
        LCResultSet *result = [db executeQuery:LCIM_SQL_SELECT_MESSAGE_BY_ID withArgumentsInArray:args];

        if ([result next]) {
            message = [self messageForRecord:result];
        }

        [result close];
    }));

    return message;
}

- (AVIMMessage *)nextMessageForId:(NSString *)messageId timestamp:(int64_t)timestamp {
    __block AVIMMessage *message = nil;

    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = @[
            self.conversationId,
            @(timestamp),
            @(timestamp),
            messageId
        ];

        LCResultSet *result = [db executeQuery:LCIM_SQL_SELECT_NEXT_MESSAGE withArgumentsInArray:args];

        if ([result next]) {
            message = [self messageForRecord:result];
        }

        [result close];
    }));

    return message;
}

- (id)messageForRecord:(LCResultSet *)record {
    AVIMMessage *message = nil;

    NSData *data = [record dataForColumn:LCIM_FIELD_PAYLOAD];
    NSString *payload = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    AVIMTypedMessageObject *messageObject = [[AVIMTypedMessageObject alloc] initWithJSON:payload];

    if ([messageObject isValidTypedMessageObject]) {
        message = [AVIMTypedMessage messageWithMessageObject:messageObject];
    } else {
        message = [[AVIMMessage alloc] init];
    }

    message.messageId          = [record stringForColumn:LCIM_FIELD_MESSAGE_ID];
    message.conversationId     = [record stringForColumn:LCIM_FIELD_CONVERSATION_ID];
    message.clientId           = [record stringForColumn:LCIM_FIELD_FROM_PEER_ID];
    message.sendTimestamp      = [record longLongIntForColumn:LCIM_FIELD_TIMESTAMP];
    message.deliveredTimestamp = [record longLongIntForColumn:LCIM_FIELD_RECEIPT_TIMESTAMP];
    message.content            = payload;
    message.status             = [record intForColumn:LCIM_FIELD_STATUS];
    message.breakpoint         = [record boolForColumn:LCIM_FIELD_BREAKPOINT];

    return message;
}

- (NSArray *)latestMessagesWithLimit:(NSUInteger)limit {
    NSMutableArray *messages = [[NSMutableArray alloc] init];

    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = @[self.conversationId, @(limit)];
        LCResultSet *result = [db executeQuery:LCIM_SQL_LATEST_MESSAGE withArgumentsInArray:args];

        while ([result next]) {
            [messages insertObject:[self messageForRecord:result] atIndex:0];
        }

        [result close];
    }));

    return messages;
}

- (AVIMMessage *)latestNoBreakpointMessage {
    __block AVIMMessage *message = nil;

    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = @[self.conversationId];
        LCResultSet *result = [db executeQuery:LCIM_SQL_LATEST_NO_BREAKPOINT_MESSAGE withArgumentsInArray:args];

        if ([result next]) {
            message = [self messageForRecord:result];
        }

        [result close];
    }));

    return message;
}

- (void)cleanCache {
    LCIM_OPEN_DATABASE(db, ({
        NSArray *args = @[self.conversationId];
        [db executeUpdate:LCIM_SQL_CLEAN_MESSAGE withArgumentsInArray:args];
    }));
}

@end
