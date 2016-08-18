//
//  LCCKSessionService.m
//  LeanCloudChatKit-iOS
//
//  v0.6.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/1.
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
@property (nonatomic, assign, getter=isPlayingSound) BOOL playingSound;

@end

@implementation LCCKSessionService
@synthesize clientId = _clientId;
@synthesize client = _client;
@synthesize forceReconnectSessionBlock = _forceReconnectSessionBlock;

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
    /* 实现了generateSignatureBlock，将对 im 的 open , start(create conv), kick, invite 操作签名，更安全.
     可以从你的服务器获得签名，也可以部署云代码获取 https://leancloud.cn/docs/leanengine_overview.html .
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
            [LCCKSingleton destroyAllInstance];
        }
    }];
}

- (void)setForceReconnectSessionBlock:(LCCKForceReconnectSessionBlock)forceReconnectSessionBlock {
    _forceReconnectSessionBlock = forceReconnectSessionBlock;
}

- (void)reconnectForViewController:(UIViewController *)viewController callback:(LCCKBooleanResultBlock)aCallback {
    LCCKForceReconnectSessionBlock forceReconnectSessionBlock = _forceReconnectSessionBlock;
    LCCKBooleanResultBlock callback = ^(BOOL succeeded, NSError *error) {
        LCCKHUDActionBlock HUDActionBlock = [LCCKUIService sharedInstance].HUDActionBlock;
        !HUDActionBlock ?: HUDActionBlock(viewController, viewController.view, nil, LCCKMessageHUDActionTypeHide);
        if (succeeded) {
            !HUDActionBlock ?: HUDActionBlock(viewController, viewController.view, LCCKLocalizedStrings(@"connectSucceeded"), LCCKMessageHUDActionTypeSuccess);
        } else {
            !HUDActionBlock ?: HUDActionBlock(viewController, viewController.view, LCCKLocalizedStrings(@"connectFailed"), LCCKMessageHUDActionTypeError);
            LCCKLog(@"%@", error.description);
        }
        !aCallback ?: aCallback(succeeded, error);
    };
    !forceReconnectSessionBlock ?: forceReconnectSessionBlock(viewController, callback);
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
    LCCKGenerateSignatureCompletionHandler completionHandler = ^(AVIMSignature *signature, NSError *error) {
        if (!error) {
            signature_ = signature;
        } else {
            NSLog(@"%@",error);
        }
    };
    generateSignatureBlock(clientId, conversationId, action, clientIds, completionHandler);
    return signature_;
}

#pragma mark - AVIMMessageDelegate

// content : "{\"_lctype\":-1,\"_lctext\":\"sdfdf\"}"  sdk 会解析好
- (void)conversation:(AVIMConversation *)conversation didReceiveTypedMessage:(AVIMTypedMessage *)message {
    if (!message.messageId) {
        LCCKLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"Receive Message , but MessageId is nil");
        return;
    }
    if (!conversation.createAt && ![[LCCKConversationService sharedInstance] isRecentConversationExistWithConversationId:conversation.conversationId]) {
        [conversation fetchWithCallback:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self receiveMessage:message conversation:conversation];
                return;
            }
            LCCKLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), error);
        }];
    } else {
        [self receiveMessage:message conversation:conversation];
    }
}

- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message {
    if (message != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageDelivered object:message];
    }
}

- (void)conversation:(AVIMConversation *)conversation didReceiveUnread:(NSInteger)unread {
    if (unread <= 0) return;
    LCCKLog(@"conversatoin:%@ didReceiveUnread:%@", conversation, @(unread));
    __weak __typeof(conversation) weakConversation = conversation;
    [conversation queryMessagesFromServerWithLimit:unread callback:^(NSArray *objects, NSError *error) {
        if (!error && (objects.count > 0)) {
            [self receiveMessages:objects conversation:weakConversation isUnreadMessage:YES];
        }
    }];
    [self playLoudReceiveSoundIfNeededForConversation:conversation];
    [conversation markAsReadInBackground];
}

- (void)conversation:(AVIMConversation *)conversation kickedByClientId:(NSString *)clientId {
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationConversationInvalided object:clientId];
    if ([[LCCKConversationService sharedInstance].currentConversationId isEqualToString:conversation.conversationId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationCurrentConversationInvalided object:clientId];
    }
}

#pragma mark - receive message handle

- (void)receiveMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation {
    if (message.mediaType > 0) {
        NSDictionary *userInfo = @{
                                   LCCKDidReceiveMessagesUserInfoConversationKey : conversation,
                                   LCCKDidReceiveCustomMessageUserInfoMessageKey : message,
                                   };
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationCustomTransientMessageReceived object:userInfo];
    }
    [self receiveMessages:@[message] conversation:conversation isUnreadMessage:NO];
}

- (void)receiveMessages:(NSArray<AVIMTypedMessage *> *)messages conversation:(AVIMConversation *)conversation isUnreadMessage:(BOOL)isUnreadMessage {
    // - 插入最近对话列表
    // 下面的LCCKNotificationMessageReceived也会通知ConversationListVC刷新
    [[LCCKConversationService sharedInstance] insertRecentConversation:conversation shouldRefreshWhenFinished:NO];
    
    // - 检查是否有人@我
    if (![[LCCKConversationService sharedInstance].currentConversationId isEqualToString:conversation.conversationId]) {
        // 没有在聊天的时候才增加未读数和设置mentioned
        [[LCCKConversationService sharedInstance] increaseUnreadCount:messages.count withConversationId:conversation.conversationId shouldRefreshWhenFinished:NO];
        [self isMentionedByMessages:messages callback:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [[LCCKConversationService sharedInstance] updateMentioned:YES conversationId:conversation.conversationId];
                // 下面的LCCKNotificationMessageReceived也会通知ConversationListVC刷新
                // [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
            }
        }];
    }
    
    // - 播放接收音
    if (!isUnreadMessage) {
        [self playLoudReceiveSoundIfNeededForConversation:conversation];
    }
    NSDictionary *userInfo = @{
                               LCCKDidReceiveMessagesUserInfoConversationKey : conversation,
                               LCCKDidReceiveMessagesUserInfoMessagesKey : messages,
                               };
    // - 通知相关页面接收到了消息：“当前对话页面”、“最近对话页面”；
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageReceived object:userInfo];
}

/*!
 * 如果是未读消息，会在 query 时播放一次，避免重复播放
 */
- (void)playLoudReceiveSoundIfNeededForConversation:(AVIMConversation *)conversation {
    if ([LCCKConversationService sharedInstance].chatting) {
        return;
    }
    if (conversation.muted) {
        return;
    }
    if (self.isPlayingSound) {
        return;
    }
    self.playingSound = YES;
    [[LCCKSoundManager defaultManager] playLoudReceiveSoundIfNeed];
    [[LCCKSoundManager defaultManager] vibrateIfNeed];
    //一定时间之内不播放声音，
    NSUInteger delaySeconds = 1;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        self.playingSound = NO;
    });
    
    
}

#pragma mark - mention

- (void)isMentionedByMessages:(NSArray<AVIMTextMessage *> *)messages callback:(LCCKBooleanResultBlock)callback {
    if (!messages || messages.count == 0) {
        NSInteger code = 0;
        NSString *errorReasonText = @"no message to check";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKSessionServiceErrorDemain
                                             code:code
                                         userInfo:errorInfo];
        !callback ?: callback(NO, error);
        return;
    }
    NSString *queueBaseLabel = [NSString stringWithFormat:@"com.chatkit.%@", NSStringFromClass([self class])];
    const char *queueName = [[NSString stringWithFormat:@"%@.ForBarrier",queueBaseLabel] UTF8String];
    dispatch_queue_t queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_CONCURRENT);
    
    __block BOOL isMentioned;
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> currentUser, NSError *error) {
        NSUInteger messagesCount = messages.count;
        [messages enumerateObjectsUsingBlock:^(AVIMTextMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![message isKindOfClass:[AVIMTextMessage class]]) {
                return;
            }
            
            dispatch_async(queue, ^(void) {
                if (isMentioned) {
                    return;
                }
                NSString *text = ((AVIMTextMessage *)message).text;
                BOOL isMentioned_ = [self isMentionedByText:text currentUser:currentUser];
                //只要有一个提及，就callback
                if (isMentioned_) {
                    isMentioned = YES;
                    *stop = YES;
                    return;
                }
            });
        }];
    }];
    
    dispatch_barrier_async(queue, ^{
        //最后一个也没有提及就callback
        NSError *error;
        if (!isMentioned) {
            NSInteger code = 0;
            NSString *errorReasonText = @"not metioned";
            NSDictionary *errorInfo = @{
                                        @"code":@(code),
                                        NSLocalizedDescriptionKey : errorReasonText,
                                        };
            error = [NSError errorWithDomain:LCCKSessionServiceErrorDemain                                                         code:code
                                    userInfo:errorInfo];
        }
        dispatch_async(dispatch_get_main_queue(),^{
            !callback ?: callback(isMentioned, error);
        });
    });
    
}

- (BOOL)isMentionedByText:(NSString *)text currentUser:(id<LCCKUserDelegate>)currentUser {
    if (!text || (text.length == 0)) {
        return NO;
    }
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

@end
