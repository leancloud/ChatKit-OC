//
//  LCCKSessionService.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSessionService.h"
#import "LCCKServiceDefinition.h"
#import "LCChatKit.h"
#import "LCCKSoundManager.h"

NSString *const LCCKSessionServiceErrorDemain = @"LCCKSessionServiceErrorDemain";

@interface LCCKSessionService() <AVIMClientDelegate, AVIMSignatureDataSource>

@property (nonatomic, copy, readwrite) NSString *clientId;

/*!
 * AVIMClient 实例
 */
@property (nonatomic, strong) AVIMClient *client;
@property (nonatomic, assign, readwrite) BOOL connect;
@property (nonatomic, copy, readwrite) LCCKSessionNotOpenedHandler sessionNotOpenedHandler;

@end

@implementation LCCKSessionService

- (void)openWithClientId:(NSString *)clientId callback:(LCCKBooleanResultBlock)callback {
    _clientId = clientId;

    [[LCCKConversationService sharedInstance] setupDatabaseWithUserId:_clientId];
    //    [[CDFailedMessageStore store] setupStoreWithDatabasePath:dbPath];
    self.client = [[AVIMClient alloc] initWithClientId:clientId];
    self.client.delegate = self;
    /* 实现了generateSignatureBlock，将对 im的 open ，start(create conv),kick,invite 操作签名，更安全
     可以从你的服务器获得签名，这里从云代码获取，需要部署云代码
     */
    if ([[LCChatKit sharedInstance] generateSignatureBlock]) {
        self.client.signatureDataSource = self;
    }
    [self.client openWithCallback:^(BOOL succeeded, NSError *error) {
        [self updateConnectStatus];
        !callback ?: callback(succeeded, error);
    }];
}

- (void)closeWithCallback:(LCCKBooleanResultBlock)callback {
    [self.client closeWithCallback:^(BOOL succeeded, NSError *error) {
        !callback ?: callback(succeeded, error);
        if (succeeded) {
            [LCCKConversationService destroyInstance];
            [LCCKSessionService destroyInstance];
        }
    }];
}

- (void)setSessionNotOpenedHandler:(LCCKSessionNotOpenedHandler)sessionNotOpenedHandler {
    _sessionNotOpenedHandler = sessionNotOpenedHandler;
}

#pragma mark - AVIMClientDelegate

- (void)imClientPaused:(AVIMClient *)imClient {
    [self updateConnectStatus];
}

- (void)imClientResuming:(AVIMClient *)imClient {
    [self updateConnectStatus];
}

- (void)imClientResumed:(AVIMClient *)imClient {
    [self updateConnectStatus];
}

#pragma mark - status

// 除了 sdk 的上面三个回调调用了，还在 open client 的时候调用了，好统一处理
- (void)updateConnectStatus {
    self.connect = self.client.status == AVIMClientStatusOpened;
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConnectivityUpdated object:@(self.connect)];
}

#pragma mark - signature

- (AVIMSignature *)signatureWithClientId:(NSString *)clientId
                          conversationId:(NSString *)conversationId
                                  action:(NSString *)action
                       actionOnClientIds:(NSArray *)clientIds {
    __block AVIMSignature *signature_;
    LCCKGenerateSignatureBlock generateSignatureBlock = [[LCChatKit sharedInstance] generateSignatureBlock];
    generateSignatureBlock(clientId, conversationId, action, clientIds, ^(AVIMSignature *signature, NSError *error) {
        if (!error) {
            signature_ = signature;
        } else {
            NSLog(@"%@",error);
        }
    });
    return signature_;
}

#pragma mark - AVIMMessageDelegate

// content : "this is message"
- (void)conversation:(AVIMConversation *)conversation didReceiveCommonMessage:(AVIMMessage *)message {
    // 不做处理，此应用没有用到
    // 可以看做跟 AVIMTypedMessage 两个频道。构造消息和收消息的接口都不一样，互不干扰。
    // 其实一般不用，有特殊的需求时可以考虑优先用 自定义 AVIMTypedMessage 来实现。见 AVIMCustomMessage 类
}

// content : "{\"_lctype\":-1,\"_lctext\":\"sdfdf\"}"  sdk 会解析好
- (void)conversation:(AVIMConversation *)conversation didReceiveTypedMessage:(AVIMTypedMessage *)message {
    if (message.messageId) {
        if (conversation.creator == nil && [[LCCKConversationService sharedInstance] isRecentConversationExist:conversation] == NO) {
            [conversation fetchWithCallback:^(BOOL succeeded, NSError *error) {
                if (error) {
                    LCCKLog(@"%@", error);
                } else {
                    [self receiveMessage:message conversation:conversation];
                }
            }];
        } else {
            [self receiveMessage:message conversation:conversation];
        }
    } else {
        LCCKLog(@"Receive Message , but MessageId is nil");
    }
}

- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message {
    LCCKLog();
    if (message != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageDelivered object:message];
    }
}

- (void)conversation:(AVIMConversation *)conversation didReceiveUnread:(NSInteger)unread {
    // 需要开启 AVIMUserOptionUseUnread 选项，见 init
    NSLog(@"conversatoin:%@ didReceiveUnread:%@", conversation, @(unread));
    [conversation markAsReadInBackground];
}

#pragma mark - receive message handle

- (void)receiveMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation {
    [[LCCKConversationService sharedInstance] insertRecentConversation:conversation];
    if (![[LCCKConversationService sharedInstance].chattingConversationId isEqualToString:conversation.conversationId]) {
        // 没有在聊天的时候才增加未读数和设置mentioned
        [[LCCKConversationService sharedInstance] increaseUnreadCountWithConversation:conversation];
        if ([self isMentionedByMessage:message]) {
            [[LCCKConversationService sharedInstance] updateMentioned:YES conversation:conversation];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
    }
    if (![LCCKConversationService sharedInstance].chattingConversationId) {
        if (!conversation.muted) {
            [[LCCKSoundManager defaultManager] playLoudReceiveSoundIfNeed];
            [[LCCKSoundManager defaultManager] vibrateIfNeed];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageReceived object:message];
}

#pragma mark - mention

- (BOOL)isMentionedByMessage:(AVIMTypedMessage *)message {
    if (![message isKindOfClass:[AVIMTextMessage class]]) {
        return NO;
    } else {
        NSString *text = ((AVIMTextMessage *)message).text;
        id<LCCKUserModelDelegate> currentUser = [[LCCKUserSystemService sharedInstance] fetchCurrentUser];
        NSString *pattern = [NSString stringWithFormat:@"@%@ ",currentUser.name];
        if([text rangeOfString:pattern].length > 0) {
            return YES;
        } else {
            return NO;
        }
    }
}

@end
