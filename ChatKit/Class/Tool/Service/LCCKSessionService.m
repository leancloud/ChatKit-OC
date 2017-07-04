//
//  LCCKSessionService.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSessionService.h"
#import "LCCKSoundManager.h"
#import "AVIMMessage+LCCKExtension.h"

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

NSString *const LCCKSessionServiceErrorDomain = @"LCCKSessionServiceErrorDomain";

@interface LCCKSessionService() <AVIMClientDelegate, AVIMSignatureDataSource>

@property (nonatomic, assign, readwrite) BOOL connect;
@property (nonatomic, assign, getter=isPlayingSound) BOOL playingSound;
@property (nonatomic, assign, getter=isRequestingSingleSignOn) BOOL requestingSingleSignOn;

@end

@implementation LCCKSessionService
@synthesize clientId = _clientId;
@synthesize client = _client;
@synthesize forceReconnectSessionBlock = _forceReconnectSessionBlock;
@synthesize disableSingleSignOn = _disableSingleSignOn;

- (void)openWithClientId:(NSString *)clientId callback:(LCCKBooleanResultBlock)callback {
    [self openWithClientId:clientId force:YES callback:callback];
}

- (void)openWithClientId:(NSString *)clientId force:(BOOL)force callback:(AVIMBooleanResultBlock)callback {
    if ([clientId lcck_isSpace]) {
        NSInteger code = 0;
        NSString *errorReasonText = @"clientId not valid";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                             code:code
                                         userInfo:errorInfo];
        
        !callback ?: callback(NO, error);
        return;
    }
    [self openSevice];
    _clientId = clientId;
    [[LCCKConversationService sharedInstance] setupDatabaseWithUserId:_clientId];
    //判断是否是第一次使用该appId
     [[LCChatKit sharedInstance] lcck_isFirstLaunchToEvent:[LCChatKit sharedInstance].appId
                                                                           evenUpdate:YES
                                                                          firstLaunch:^BOOL(){
                                                                              return [[LCChatKit sharedInstance] removeAllCachedRecentConversations];
                                                                          }];
    NSString *tag;
    if (!self.disableSingleSignOn) {
        tag = clientId;
    }
    _client = [[AVIMClient alloc] initWithClientId:clientId tag:tag];
    _client.delegate = self;
    /* 实现了generateSignatureBlock，将对 im 的 open , start(create conv), kick, invite 操作签名，更安全.
     可以从你的服务器获得签名，也可以部署云代码获取 https://leancloud.cn/docs/leanengine_overview.html .
     */
    if ([[LCChatKit sharedInstance] generateSignatureBlock]) {
        _client.signatureDataSource = self;
    }
    AVIMClientOpenOption *option = [AVIMClientOpenOption new];
    option.force = force;
    [_client openWithOption:option callback:^(BOOL succeeded, NSError *error) {
        [self updateConnectStatus];
        
        BOOL isFirstLaunchForClientId = [[LCChatKit sharedInstance] lcck_isFirstLaunchToEvent:clientId
                                                                                   evenUpdate:YES
                                                                                  firstLaunch:^BOOL(){
                                                                                      return YES;
                                                                                  }];
        if (succeeded && isFirstLaunchForClientId) {
            [[LCCKConversationListService sharedInstance] fetchRelationConversationsFromServer:^(NSArray * _Nullable conversations, NSError * _Nullable error) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    [[LCCKConversationService sharedInstance] insertRecentConversations:conversations shouldRefreshWhenFinished:NO];
                    dispatch_async(dispatch_get_main_queue(),^{
                        !callback ?: callback(succeeded, error);
                    });
                });
            }];
        } else {
            !callback ?: callback(succeeded, error);
        }
        if (error.code == 4111) {
            [self handleSingleSignOnError:error callback:^(BOOL succeeded, NSError *error) {
                !callback ?: callback(succeeded, error);
            }];
        }
    }];
}

- (void)closeWithCallback:(LCCKBooleanResultBlock)callback {
    [_client closeWithCallback:^(BOOL succeeded, NSError *error) {
        !callback ?: callback(succeeded, error);
        if (succeeded) {
            [self resetService];
        }
    }];
}

- (void)openSevice {
    [LCCKConversationListService sharedInstance];
    [LCCKConversationService sharedInstance];
    [LCCKSessionService sharedInstance];
    [LCCKSettingService sharedInstance];
    [LCCKSignatureService sharedInstance];
    [LCCKUIService sharedInstance];
    [LCCKUserSystemService sharedInstance];
}

- (void)resetService {
    [LCCKSingleton destroyAllInstance];
}

- (void)setForceReconnectSessionBlock:(LCCKForceReconnectSessionBlock)forceReconnectSessionBlock {
    _forceReconnectSessionBlock = forceReconnectSessionBlock;
}

- (void)reconnectForViewController:(UIViewController *)viewController callback:(LCCKBooleanResultBlock)aCallback {
    [self reconnectForViewController:viewController error:nil granted:YES callback:aCallback];
}

- (void)reconnectForViewController:(UIViewController *)viewController error:(NSError *)aError granted:(BOOL)granted callback:(LCCKBooleanResultBlock)aCallback {
    LCCKForceReconnectSessionBlock forceReconnectSessionBlock = _forceReconnectSessionBlock;
    LCCKBooleanResultBlock completionHandler = ^(BOOL succeeded, NSError *error) {
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
    !forceReconnectSessionBlock ?: forceReconnectSessionBlock(aError, granted, viewController, completionHandler);
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

- (void)handleSingleSignOnError:(NSError *)aError callback:(LCCKBooleanResultBlock)aCallback {
    if (aError.code == 4111) {
        [self resetService];
        [self requestForceSingleSignOnAuthorizationWithCallback:^(BOOL granted, NSError *theError) {
            [self reconnectForViewController:nil error:aError granted:granted callback:aCallback];
        }];
    }
}

- (void)client:(AVIMClient *)client didOfflineWithError:(NSError *)aError {
    [self handleSingleSignOnError:aError callback:nil];
}

- (void)requestForceSingleSignOnAuthorizationWithCallback:(LCCKRequestAuthorizationBoolResultBlock)callback {
    if (self.isRequestingSingleSignOn) {
        return;
    }
    self.requestingSingleSignOn = YES;
    NSString *title = LCCKLocalizedStrings(@"requestForceSingleSignOnAuthorization");
    LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                       message:@""
                                                                preferredStyle:LCCKAlertControllerStyleAlert];
    NSString *cancelActionTitle = LCCKLocalizedStrings(@"cancel") ?: @"取消";
    LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                             handler:^(LCCKAlertAction * action) {
                                                                 NSInteger code = 0;
                                                                 NSString *errorReasonText = @"request force single sign on failed";
                                                                 NSDictionary *errorInfo = @{
                                                                                             @"code":@(code),
                                                                                             NSLocalizedDescriptionKey : errorReasonText,
                                                                                             };
                                                                 NSError *error = [NSError errorWithDomain:LCCKSessionServiceErrorDomain
                                                                                                      code:code
                                                                                                  userInfo:errorInfo];
                                                                 !callback ?: callback(NO, error);
                                                                 self.requestingSingleSignOn = NO;
                                                             }];
    [alert addAction:cancelAction];
    
    NSString *forceOpenActionTitle = LCCKLocalizedStrings(@"ok") ?: @"确认";
    LCCKAlertAction *forceOpenAction = [LCCKAlertAction actionWithTitle:forceOpenActionTitle style:LCCKAlertActionStyleDefault
                                                                handler:^(LCCKAlertAction * action) {
                                                                    !callback ?: callback(YES, nil);
                                                                    self.requestingSingleSignOn = NO;
                                                                }];
    [alert addAction:forceOpenAction];
    [alert showWithSender:nil controller:nil animated:YES completion:NULL];
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

/*!
 * 低版本如果不支持某自定义消息，该自定义消息会走该代理
 */
- (void)conversation:(AVIMConversation *)conversation didReceiveCommonMessage:(AVIMMessage *)message {
    if (!message.lcck_isValidMessage) {
        return;
    }
    AVIMTypedMessage *typedMessage = [message lcck_getValidTypedMessage];
    [self conversation:conversation didReceiveTypedMessage:typedMessage];
}

- (void)conversation:(AVIMConversation *)conversation didReceiveTypedMessage:(AVIMTypedMessage *)message {
    if (!message.lcck_isValidMessage) {
        return;
    }
    if (!message.messageId) {
        LCCKLog(@"�类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"Receive Message , but MessageId is nil");
        return;
    }
    void (^fetchedConversationCallback)() = ^() {
        [self receiveMessage:message conversation:conversation];
    };
    [self makeSureConversation:conversation isAvailableCallback:fetchedConversationCallback];
}

- (void)conversation:(AVIMConversation *)conversation messageDelivered:(AVIMMessage *)message {
    [self didReceiveStatusMessage:message conversation:conversation];
}

- (void)conversation:(AVIMConversation *)conversation messageRead:(AVIMMessage *)message {
    [self didReceiveStatusMessage:message conversation:conversation];
}

- (void)didReceiveStatusMessage:(AVIMMessage *)message conversation:(AVIMConversation *)conversation {
    if (!message.lcck_isValidMessage) {
        return;
    }
    NSDictionary *userInfo = @{
                               LCCKMessageNotifacationUserInfoConversationKey : conversation,
                               LCCKMessageNotifacationUserInfoMessageKey : message,
                               };
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageDelivered object:userInfo];
}

- (void)conversation:(AVIMConversation *)conversation didReceiveUnread:(NSInteger)unread {
    if (unread <= 0) return;
    LCCKLog(@"conversatoin:%@ didReceiveUnread:%@", conversation, @(unread));
    void (^fetchedConversationCallback)() = ^() {
        [conversation queryMessagesFromServerWithLimit:unread callback:^(NSArray *objects, NSError *error) {
            if (!error && (objects.count > 0)) {
                [self receiveMessages:objects conversation:conversation isUnreadMessage:YES];
            }
        }];
        [self playLoudReceiveSoundIfNeededForConversation:conversation];
        //        [conversation markAsReadInBackground];
        //FIXME:
//        [conversation markAsReadInBackgroundForMessage:conversation.lcck_lastMessage];

    };
    [self makeSureConversation:conversation isAvailableCallback:fetchedConversationCallback];
}

- (void)makeSureConversation:(AVIMConversation *)conversation isAvailableCallback:(LCCKVoidBlock)callback {
    if (!conversation.createAt && ![[LCCKConversationService sharedInstance] isRecentConversationExistWithConversationId:conversation.conversationId]) {
        [conversation fetchWithCallback:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                !callback ?: callback();
                return;
            }
            LCCKLog(@"�类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), error);
        }];
    } else {
        !callback ?: callback();
    }
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
                                   LCCKMessageNotifacationUserInfoConversationKey : conversation,
                                   LCCKDidReceiveCustomMessageUserInfoMessageKey : message,
                                   };
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationCustomTransientMessageReceived object:userInfo];
    }
    [self receiveMessages:@[message] conversation:conversation isUnreadMessage:NO];
}

- (void)receiveMessages:(NSArray<AVIMTypedMessage *> *)messages conversation:(AVIMConversation *)conversation isUnreadMessage:(BOOL)isUnreadMessage {
    
    void (^checkMentionedMessageCallback)() = ^(NSArray *filterdMessages) {
        // - 插入最近对话列表
        // 下面的LCCKNotificationMessageReceived也会通知ConversationListVC刷新
        [[LCCKConversationService sharedInstance] insertRecentConversation:conversation shouldRefreshWhenFinished:NO];
        [[LCCKConversationService sharedInstance] increaseUnreadCount:filterdMessages.count withConversationId:conversation.conversationId shouldRefreshWhenFinished:NO];
        // - 播放接收音
        if (!isUnreadMessage) {
            [self playLoudReceiveSoundIfNeededForConversation:conversation];
        }
        NSDictionary *userInfo = @{
                                   LCCKMessageNotifacationUserInfoConversationKey : conversation,
                                   LCCKDidReceiveMessagesUserInfoMessagesKey : filterdMessages,
                                   };
        // - 通知相关页面接收到了消息：“当前对话页面”、“最近对话页面”；
        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageReceived object:userInfo];
        
        
        AVIMTypedMessage * userObj = userInfo[@"receivedMessages"][0];
        NSDictionary * userInformation = userObj.attributes;
        
        NSString *userSex = userInformation[@"USER_SEX"];
        NSString *userIcon = userInformation[@"USER_ICON"];
        NSString *userName = userInformation[@"USER_NAME"];
        NSString *userId = userInformation[@"USER_ID"];
        
        // TODO 未识别的时候是返回custom:1。然后数据全丢了。。。
        if(userSex == nil) {
            userSex = @"";
        }
        
        if(userIcon == nil) {
            userIcon = @"";
        }
        
        if(userName == nil) {
            userName = @"";
        }
        
        if(userId == nil) {
            userId = userObj.clientId;
        }
        
        NSString * finalMessage = @"";
        
        if (userObj.mediaType == kAVIMMessageMediaTypeText) {
            finalMessage = userObj.text;
        } else if (userObj.mediaType == kAVIMMessageMediaTypeAudio) {
            finalMessage = @"语音消息";
        } else if (userObj.mediaType == kAVIMMessageMediaTypeImage) {
            finalMessage = @"图片消息";
        } else {
            if (userObj.text != nil) {
                finalMessage = userObj.text;
            } else {
                finalMessage = @"收到新消息";
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sendMessageToRNNotificationName" object:@{
                                                                                                               @"USER_SEX": userSex,                                  @"USER_ICON": userIcon,                                  @"USER_NAME": userName,                                      @"USER_ID": userId, @"MESSAGE_TYPE": @"MESSAGE_TYPE_CHAT",
                                                                                                               @"CHAT_TIME": [NSString stringWithFormat:@"%f", LCCK_CURRENT_TIMESTAMP],
                                                                                                               @"CHAT_MESSAGE":finalMessage
                                                                                                               }];
        
    };
    
    void(^filteredMessageCallback)(NSArray *originalMessages) = ^(NSArray *filterdMessages) {
        if (filterdMessages.count == 0) { return; }
        // - 在最近对话列表页时，检查是否有人@我
        if (![[LCCKConversationService sharedInstance].currentConversationId isEqualToString:conversation.conversationId]) {
            // 没有在聊天的时候才增加未读数和设置mentioned
            [self isMentionedByMessages:filterdMessages callback:^(BOOL succeeded, NSError *error) {
                !checkMentionedMessageCallback ?: checkMentionedMessageCallback(filterdMessages);
                if (succeeded) {
                    [[LCCKConversationService sharedInstance] updateMentioned:YES conversationId:conversation.conversationId];
                    // 下面的LCCKNotificationMessageReceived也会通知ConversationListVC刷新
                    // [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
                }
            }];
        } else {
            !checkMentionedMessageCallback ?: checkMentionedMessageCallback(filterdMessages);
        }
    };
    
    LCCKFilterMessagesBlock filterMessagesBlock = [LCCKConversationService sharedInstance].filterMessagesBlock;
    if (filterMessagesBlock) {
        LCCKFilterMessagesCompletionHandler filterMessagesCompletionHandler = ^(NSArray *filteredMessages, NSError *error) {
            if (!error) {
                !filteredMessageCallback ?: filteredMessageCallback([filteredMessages copy]);
            }
        };
        filterMessagesBlock(conversation, messages, filterMessagesCompletionHandler);
    } else {
        !filteredMessageCallback ?: filteredMessageCallback(messages);
    }
}

/*!
 * 如果是未读消息，会在 query 时播放一次，避免重复播放
 */
- (void)playLoudReceiveSoundIfNeededForConversation:(AVIMConversation *)conversation {
    if ([LCCKConversationService sharedInstance].chatting) {
        //FIXME:
//        [conversation markAsReadInBackgroundForMessage:conversation.lcck_lastMessage];
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
    //一定时间之内只播放声音一次
    NSUInteger delaySeconds = 1;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        self.playingSound = NO;
    });
}

#pragma mark - mention

- (void)isMentionedByMessages:(NSArray<AVIMTypedMessage *> *)messages callback:(LCCKBooleanResultBlock)callback {
    if (!messages || messages.count == 0) {
        NSInteger code = 0;
        NSString *errorReasonText = @"no message to check";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKSessionServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        !callback ?: callback(NO, error);
        return;
    }

    __block BOOL isMentioned = NO;
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> currentUser, NSError *error) {
        NSString *queueBaseLabel = [NSString stringWithFormat:@"com.chatkit.%@", NSStringFromClass([self class])];
        const char *queueName = [[NSString stringWithFormat:@"%@.%@.ForBarrier",queueBaseLabel, [[NSUUID UUID] UUIDString]] UTF8String];
        dispatch_queue_t queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_CONCURRENT);
        
        [messages enumerateObjectsUsingBlock:^(AVIMTypedMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
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
        
        dispatch_barrier_async(queue, ^{
            //最后一个也没有提及就callback
            NSError *error = nil;
            if (!isMentioned) {
                NSInteger code = 0;
                NSString *errorReasonText = @"not mentioned";
                NSDictionary *errorInfo = @{
                                            @"code":@(code),
                                            NSLocalizedDescriptionKey : errorReasonText,
                                            };
                error = [NSError errorWithDomain:LCCKSessionServiceErrorDomain                                                         code:code
                                        userInfo:errorInfo];
            }
            dispatch_async(dispatch_get_main_queue(),^{
                !callback ?: callback(isMentioned, error);
            });
        });
        
    }];
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
