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
#import "NSString+LCCKExtension.h"

NSString *const LCCKSessionServiceErrorDemain = @"LCCKSessionServiceErrorDemain";

@interface LCCKSessionService() <AVIMClientDelegate, AVIMSignatureDataSource>

@property (nonatomic, assign, readwrite) BOOL connect;

@end

@implementation LCCKSessionService
@synthesize clientId = _clientId;
@synthesize client = _client;
@synthesize sessionNotOpenedHandler = _sessionNotOpenedHandler;

- (void)openWithClientId:(NSString *)clientId callback:(LCCKBooleanResultBlock)callback {
    _clientId = clientId;
    [[LCCKConversationService sharedInstance] setupDatabaseWithUserId:_clientId];
    //判断是否是第一次使用该appId
    [[LCChatKit sharedInstance] lcck_isFirstLaunchToEvent:[LCChatKit sharedInstance].appId
                                               evenUpdate:YES
                                              firstLaunch:^BOOL(){
                                                   return [[LCChatKit sharedInstance] removeAllCachedRecentConversations];
                                              }];
    //    [[CDFailedMessageStore store] setupStoreWithDatabasePath:dbPath];
    _client = [[AVIMClient alloc] initWithClientId:clientId];
    _client.delegate = self;
    /* 实现了generateSignatureBlock，将对 im的 open ，start(create conv),kick,invite 操作签名，更安全
     可以从你的服务器获得签名，这里从云代码获取，需要部署云代码
     */
    if ([[LCChatKit sharedInstance] generateSignatureBlock]) {
        _client.signatureDataSource = self;
    }
    [_client openWithCallback:^(BOOL succeeded, NSError *error) {
        [self updateConnectStatus];
        !callback ?: callback(succeeded, error);
    }];
}

- (void)closeWithCallback:(LCCKBooleanResultBlock)callback {
    [_client closeWithCallback:^(BOOL succeeded, NSError *error) {
        !callback ?: callback(succeeded, error);
        if (succeeded) {
            [LCCKConversationListService destroyInstance];
            [LCCKConversationService destroyInstance];
            [LCCKSessionService destroyInstance];
            [LCCKSessionService destroyInstance];
            [LCCKSettingService destroyInstance];
            [LCCKSignatureService destroyInstance];
            [LCCKUIService destroyInstance];
            [LCCKUserSystemService destroyInstance];
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
    self.connect = _client.status == AVIMClientStatusOpened;
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
        if (conversation.creator == nil && [[LCCKConversationService sharedInstance] isRecentConversationExistWithConversationId:conversation.conversationId] == NO) {
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

//TODO:推荐使用这种方式接收离线消息
- (void)conversation:(AVIMConversation *)conversation didReceiveUnread:(NSInteger)unread {
    // 需要开启 AVIMUserOptionUseUnread 选项，见 init
    NSLog(@"conversatoin:%@ didReceiveUnread:%@", conversation, @(unread));
    [conversation markAsReadInBackground];
}

#pragma mark - receive message handle

- (void)receiveMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation {
    [[LCCKConversationService sharedInstance] insertRecentConversation:conversation];
    if (![[LCCKConversationService sharedInstance].currentConversationId isEqualToString:conversation.conversationId]) {
        // 没有在聊天的时候才增加未读数和设置mentioned
        [[LCCKConversationService sharedInstance] increaseUnreadCountWithConversationId:conversation.conversationId];
        if ([self isMentionedByMessage:message]) {
            [[LCCKConversationService sharedInstance] updateMentioned:YES conversationId:conversation.conversationId];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
    }
    if (![LCCKConversationService sharedInstance].currentConversationId) {
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
        id<LCCKUserDelegate> currentUser = [[LCCKUserSystemService sharedInstance] fetchCurrentUser];
        NSString *patternWithUserName = [NSString stringWithFormat:@"@%@ ",currentUser.name ?: currentUser.clientId];
        NSString *patternWithLowercaseAll = @"@all ";
        NSString *patternWithUppercaseAll = @"@All ";
        BOOL isMentioned = [text lcck_containsString:patternWithUserName] || [text lcck_containsString:patternWithLowercaseAll] || [text lcck_containsString:patternWithUppercaseAll];
        if(isMentioned) {
            return YES;
        } else {
            return NO;
        }
    }
}

@end
