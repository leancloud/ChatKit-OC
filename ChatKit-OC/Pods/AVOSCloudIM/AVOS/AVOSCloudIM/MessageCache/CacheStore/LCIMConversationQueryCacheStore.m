//
//  LCIMConversationQueryCacheStore.m
//  AVOS
//
//  Created by Tang Tianyong on 8/31/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCIMConversationQueryCacheStore.h"
#import "LCIMCacheStore.h"
#import "AVIMConversationOutCommand.h"
#import "NSDictionary+LCHash.h"

#define LCIM_CONVERSATION_QUERY_TABLE_NAME @"command_query"

@implementation LCIMConversationQueryCacheStore

- (instancetype)initWithClientId:(NSString *)clientId {
    NSString *databasePath = [LCIMCacheStore databasePathWithName:clientId];
    self = [super initWithDatabasePath:databasePath tableName:LCIM_CONVERSATION_QUERY_TABLE_NAME];

    if (self) {
        _clientId = [clientId copy];
    }

    return self;
}

- (NSDictionary *)dictionaryForCommand:(AVIMConversationOutCommand *)command {
    NSMutableDictionary *dictionary = [[command dictionary] mutableCopy];
    [dictionary removeObjectForKey:@"i"]; // Remove the serial id for command

    return [dictionary copy];
}

- (void)cacheConversationIds:(NSArray *)conversationIds forCommand:(AVIMConversationOutCommand *)command {
    NSString *key = [[self dictionaryForCommand:command] lc_SHA1String];
    NSData *data  = [[conversationIds componentsJoinedByString:@","] dataUsingEncoding:NSUTF8StringEncoding];

    [self setData:data forKey:key];
}

- (NSArray *)conversationIdsForCommand:(AVIMConversationOutCommand *)command {
    NSArray *result = nil;

    NSString *key = [[self dictionaryForCommand:command] lc_SHA1String];
    NSData *data  = [self dataForKey:key];

    if (data) {
        NSString *ids = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        result = [ids componentsSeparatedByString:@","];
    }

    return result;
}

- (void)removeConversationIdsForCommand:(AVIMConversationOutCommand *)command {
    NSString *key = [[self dictionaryForCommand:command] lc_SHA1String];

    [self deleteKey:key];
}

@end
