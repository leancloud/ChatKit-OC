//
//  LCIMSessionService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMSessionService.h"
#import "LCIMServiceDefinition.h"
#import "LCIMKit.h"
#import "LCIMKit_Internal.h"
#import "LCIMSoundManager.h"

NSString *const LCIMSessionServiceErrorDemain = @"LCIMSessionServiceErrorDemain";

@interface LCIMSessionService() <AVIMClientDelegate, AVIMSignatureDataSource>

@property (nonatomic, copy, readwrite) NSString *clientId;

/*!
 * AVIMClient 实例
 */
@property (nonatomic, strong) AVIMClient *client;
@property (nonatomic, assign, readwrite) BOOL connect;

@end
@implementation LCIMSessionService

/**
 * create a singleton instance of LCIMSessionService
 */
+ (instancetype)sharedInstance {
    static LCIMSessionService *_sharedLCIMSessionService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMSessionService = [[self alloc] init];
    });
    return _sharedLCIMSessionService;
}

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback {
    _clientId = clientId;

    [[LCIMConversationService sharedInstance] setupDatabaseWithUserId:_clientId];
    //    [[CDFailedMessageStore store] setupStoreWithDatabasePath:dbPath];
    self.client = [[AVIMClient alloc] initWithClientId:clientId];
    self.client.delegate = self;
    /* 实现了generateSignatureBlock，将对 im的 open ，start(create conv),kick,invite 操作签名，更安全
     可以从你的服务器获得签名，这里从云代码获取，需要部署云代码，https://github.com/leancloud/leanchat-cloudcode
     */
    if ([[LCIMKit sharedInstance] generateSignatureBlock]) {
        self.client.signatureDataSource = self;
    }
    [self.client openWithCallback:^(BOOL succeeded, NSError *error) {
        [self updateConnectStatus];
        !callback ?: callback(succeeded, error);
    }];
}

- (void)closeWithCallback:(LCIMBooleanResultBlock)callback {
    [self.client closeWithCallback:^(BOOL succeeded, NSError *error) {
        !callback ?: callback(succeeded, error);
    }];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationConnectivityUpdated object:@(self.connect)];
}

#pragma mark - signature

- (AVIMSignature *)signatureWithClientId:(NSString *)clientId
                          conversationId:(NSString *)conversationId
                                  action:(NSString *)action
                       actionOnClientIds:(NSArray *)clientIds {
    __block AVIMSignature *signature_;
    LCIMGenerateSignatureBlock generateSignatureBlock = [[LCIMKit sharedInstance] generateSignatureBlock];
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
        if (conversation.creator == nil && [[LCIMConversationService sharedInstance] isRecentConversationExist:conversation] == NO) {
            [conversation fetchWithCallback:^(BOOL succeeded, NSError *error) {
                if (error) {
                    DLog(@"%@", error);
                } else {
                    [self receiveMessage:message conversation:conversation];
                }
            }];
        } else {
            [self receiveMessage:message conversation:conversation];
        }
    } else {
        DLog(@"Receive Message , but MessageId is nil");
    }
}

- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message {
    DLog();
    if (message != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationMessageDelivered object:message];
    }
}

- (void)conversation:(AVIMConversation *)conversation didReceiveUnread:(NSInteger)unread {
    // 需要开启 AVIMUserOptionUseUnread 选项，见 init
    NSLog(@"conversatoin:%@ didReceiveUnread:%@", conversation, @(unread));
    [conversation markAsReadInBackground];
}

#pragma mark - receive message handle

- (void)receiveMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation{
    [[LCIMConversationService sharedInstance] insertRecentConversation:conversation];
    if (![[LCIMConversationService sharedInstance].chattingConversationId isEqualToString:conversation.conversationId]) {
        // 没有在聊天的时候才增加未读数和设置mentioned
        [[LCIMConversationService sharedInstance] increaseUnreadCountWithConversation:conversation];
        if ([self isMentionedByMessage:message]) {
            [[LCIMConversationService sharedInstance] updateMentioned:YES conversation:conversation];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationUnreadsUpdated object:nil];
    }
    if (![LCIMConversationService sharedInstance].chattingConversationId) {
        if (!conversation.muted) {
            [[LCIMSoundManager defaultManager] playLoudReceiveSoundIfNeed];
            [[LCIMSoundManager defaultManager] vibrateIfNeed];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationMessageReceived object:message];
}

#pragma mark - mention

- (BOOL)isMentionedByMessage:(AVIMTypedMessage *)message {
    if (![message isKindOfClass:[AVIMTextMessage class]]) {
        return NO;
    } else {
        NSString *text = ((AVIMTextMessage *)message).text;
        id<LCIMUserModelDelegate> currentUser = [[LCIMUserSystemService sharedInstance] fetchCurrentUser];
        NSString *pattern = [NSString stringWithFormat:@"@%@ ",currentUser.name];
        if([text rangeOfString:pattern].length > 0) {
            return YES;
        } else {
            return NO;
        }
    }
}

@end
