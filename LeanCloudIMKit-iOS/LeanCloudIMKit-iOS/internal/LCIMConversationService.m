//
//  LCIMConversationService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMConversationService.h"
#import "LCIMKit.h"
#import "LCIMUtil.h"

@interface LCIMConversationService()

@property (nonatomic, strong) AVIMClient *client;

@end

@implementation LCIMConversationService

- (AVIMConversation *)fetchConversationByConversationId:(NSString *)conversationId {
    //TODO:
    return nil;
}
/**
 *  根据 conversationId 获取对话
 *  @param convid   对话的 id
 *  @param callback
 */
- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(AVIMConversationResultBlock)callback {
    NSAssert(conversationId.length > 0, @"Conversation id is nil");
    AVIMConversationQuery *q = [self.client conversationQuery];
    q.cachePolicy = kAVIMCachePolicyNetworkElseCache;
    [q whereKey:@"objectId" equalTo:conversationId];
    [q findConversationsWithCallback: ^(NSArray *objects, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            if (objects.count == 0) {
                callback(nil, [LCIMUtil errorWithText:[NSString stringWithFormat:@"conversation of %@ not exists", conversationId]]);
            } else {
                callback([objects objectAtIndex:0], error);
            }
        }
    }];
}

- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback {
    if ([peerId isEqualToString:[[LCIMKit sharedInstance] clientId]]) {
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
    
    //    [self.client createConversationWithName:name clientIds:members attributes:@{ CONVERSATION_TYPE:@(type) } options:options callback:callback];
}


@end
