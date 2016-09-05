//
//  AVHistoryMessageQuery.m
//  AVOS
//
//  Created by Qihe Bian on 10/21/14.
//
//

#import "AVHistoryMessageQuery.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import "AVHistoryMessage.h"
#import "AVSession.h"

@interface AVHistoryMessageQuery ()
@property(nonatomic, strong)NSString *conversationId;
@property(nonatomic, strong)NSString *fromPeerId;
@property(nonatomic, strong)NSString *firstPeerId;
@property(nonatomic, strong)NSString *secondPeerId;
@property(nonatomic, strong)NSString *groupId;
@end
@implementation AVHistoryMessageQuery

+ (instancetype)query {
    return [self queryWithTimestamp:0 limit:0];
}

+ (instancetype)queryWithTimestamp:(int64_t)timestamp limit:(int)limit {
    return [self queryWithConversationId:nil timestamp:timestamp limit:limit];
}

+ (instancetype)queryWithConversationId:(NSString *)conversationId {
    return [self queryWithConversationId:conversationId timestamp:0 limit:0];
}

+ (instancetype)queryWithConversationId:(NSString *)conversationId timestamp:(int64_t)timestamp limit:(int)limit {
    AVHistoryMessageQuery *query = [[self alloc] init];
    query.conversationId = conversationId;
    query.timestamp = timestamp;
    query.limit = limit;
    return query;
}

+ (instancetype)queryWithFromPeerId:(NSString *)fromPeerId {
    return [self queryWithFromPeerId:fromPeerId timestamp:0 limit:0];
}

+ (instancetype)queryWithFromPeerId:(NSString *)fromPeerId timestamp:(int64_t)timestamp limit:(int)limit {
    AVHistoryMessageQuery *query = [[self alloc] init];
    query.fromPeerId = fromPeerId;
    query.timestamp = timestamp;
    query.limit = limit;
    return query;
}

+ (instancetype)queryWithFirstPeerId:(NSString *)firstPeerId secondPeerId:(NSString *)secondPeerId {
    return [self queryWithFirstPeerId:firstPeerId secondPeerId:secondPeerId timestamp:0 limit:0];
}

+ (instancetype)queryWithFirstPeerId:(NSString *)firstPeerId secondPeerId:(NSString *)secondPeerId timestamp:(int64_t)timestamp limit:(int)limit {
    if (!firstPeerId || !secondPeerId) {
        return nil;
    }
//    NSMutableArray *items = [[NSMutableArray alloc] initWithObjects:firstPeerId, secondPeerId, nil];
//    [items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//        return [obj1 compare:obj2];
//    }];
    if ([firstPeerId compare:secondPeerId] == NSOrderedDescending) {
        NSString *temp = firstPeerId;
        firstPeerId = secondPeerId;
        secondPeerId = temp;
    }
    NSString *s = [NSString stringWithFormat:@"%@:%@", firstPeerId, secondPeerId];
    NSString *conversationId = [[s AVMD5String] lowercaseString];
    AVHistoryMessageQuery *query = [[self alloc] init];
    query.firstPeerId = firstPeerId;
    query.secondPeerId = secondPeerId;
    query.conversationId = conversationId;
    query.timestamp = timestamp;
    query.limit = limit;
    return query;
}

+ (instancetype)queryWithGroupId:(NSString *)groupId {
    return [self queryWithGroupId:groupId timestamp:0 limit:0];
}

+ (instancetype)queryWithGroupId:(NSString *)groupId timestamp:(int64_t)timestamp limit:(int)limit {
    AVHistoryMessageQuery *query = [[self alloc] init];
    query.groupId = groupId;
    query.conversationId = groupId;
    query.timestamp = timestamp;
    query.limit = limit;
    return query;
}

-(NSArray *)find {
    return [self find:NULL];
}

-(NSArray *)find:(NSError **)error {
    return [self findInBackgroundWithCallback:nil waitUntilDone:YES error:error];
}

-(void)findInBackgroundWithCallback:(AVArrayResultBlock)callback {
    [self findInBackgroundWithCallback:callback waitUntilDone:NO error:NULL];
}

-(NSArray *)findInBackgroundWithCallback:(AVArrayResultBlock)callback
            waitUntilDone:(BOOL)wait
                    error:(NSError **)error {
    
    __block NSArray *result = nil;
    __block BOOL hasCalledBack = NO;
    __block NSError *blockError = nil;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (self.conversationId) {
        [dict setObject:self.conversationId forKey:@"convid"];
    }
    if (self.fromPeerId) {
        [dict setObject:self.fromPeerId forKey:@"from"];
    }
    if (self.timestamp != 0) {
        [dict setObject:@(self.timestamp) forKey:@"timestamp"];
    }
    if (self.limit != 0) {
        [dict setObject:@(self.limit) forKey:@"limit"];
    }
    [[AVPaasClient sharedInstance] getObject:@"rtm/messages/logs/" withParameters:dict block:^(id object, NSError *error) {
        NSMutableArray *array = nil;
        if (!error) {
            array = [[NSMutableArray alloc] init];
            for (NSDictionary *item in object) {
                AVHistoryMessage *message = [[AVHistoryMessage alloc] init];
                message.timestamp = [[item objectForKey:@"timestamp"] longLongValue];
                message.fromPeerId = [item objectForKey:@"from"];
                message.payload = [item objectForKey:@"data"];
                message.conversationId = [item objectForKey:@"conv-id"];
                id to = [item objectForKey:@"to"];
                NSString *toId = nil;
                if ([to isKindOfClass:[NSString class]]) {
                    toId = to;
                } else if ([to isKindOfClass:[NSArray class]]) {
                    toId = [to firstObject];
                }
                AVSession *session = [AVSession getSessionWithPeerId:message.fromPeerId];
                AVMessageType peerType = AVMessageTypePeerIn;
                AVMessageType groupType = AVMessageTypePeerIn;
                if (session) {
                    peerType = AVMessageTypePeerOut;
                    groupType = AVMessageTypeGroupOut;
                }
                message.type = [[item objectForKey:@"is-room"] boolValue]?groupType:peerType;
                if (message.type == AVMessageTypeGroupIn || message.type == AVMessageTypeGroupOut) {
                    message.groupId = toId;
                } else if (message.type == AVMessageTypePeerIn || message.type == AVMessageTypePeerOut) {
                    message.toPeerId = toId;
                }
                [array addObject:message];
            }
        }
        [AVUtils callArrayResultBlock:callback array:array error:error];
        if (wait) {
            blockError = error;
            result = array;
            hasCalledBack = YES;
        }
    }];
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (error != NULL) *error = blockError;
    return result;
}
@end
