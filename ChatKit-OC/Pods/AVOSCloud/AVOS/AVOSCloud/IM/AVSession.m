//
//  AVSession.m
//  paas
//
//  Created by yang chaozhong on 5/6/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "AVSession.h"
#import "AVWebSocketWrapper.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import "AVGroup_Internal.h"
#import "AVSession_Internal.h"

#define DEFAULT_ACK_CHECK_INTERVAL 10

static NSMutableDictionary *_sessionDict = nil;
static dispatch_queue_t _sessionQueue = 0;

@implementation AVSession

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (instancetype)getSessionWithPeerId:(NSString *)peerId {
    return [self getSessionWithPeerId:peerId createAndOpenWhenNotExists:NO sessionDelegate:nil signatureDelegate:nil];
}

+ (instancetype)getSessionWithPeerId:(NSString *)peerId
          createAndOpenWhenNotExists:(BOOL)createAndOpen
                     sessionDelegate:(id<AVSessionDelegate>)sessionDelegate
                   signatureDelegate:(id<AVSignatureDelegate>)signatureDelegate
{
    AVSession *session = [_sessionDict objectForKey:peerId];
    if (!session && createAndOpen) {
        session = [[AVSession alloc] init];
        session.sessionDelegate = sessionDelegate;
        session.signatureDelegate = signatureDelegate;
        [session openWithPeerId:peerId];
    }
    return session;
}

+ (dispatch_queue_t)sessionQueue {
    return _sessionQueue;
}

- (id)init {
    self = [super init];
    if (self) {
        if (!_sessionDict) {
            _sessionDict = [[NSMutableDictionary alloc] init];
        }
        if (!_sessionQueue) {
            _sessionQueue = dispatch_queue_create("cn.leancloud.sdk.session", DISPATCH_QUEUE_SERIAL);
        }
        _receiptDictionary = [[NSMutableDictionary alloc] init];
        _watchedPeerIds = [[NSMutableSet alloc] init];
        _onlinePeerIds = [[NSMutableSet alloc] init];
        _queryCallbackQueue = [[NSMutableArray alloc] init];
        _ackCommandQueue = [[NSMutableArray alloc] init];
        _unInitializedGroups = [[NSMutableArray alloc] init];
        _paused = NO;
        _opened = NO;
        self.messageTimeout = DEFAULT_ACK_CHECK_INTERVAL;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivePaused) name:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:self];
    }
    return self;
}

- (void)dealloc {
    AVLoggerInfo(AVLoggerDomainIM, @"Session deallocated.");
    [[AVWebSocketWrapper sharedInstance].delegateDict removeObjectForKey:_peerId];
    [_sessionDict removeObjectForKey:_peerId];
    if ([AVWebSocketWrapper sharedInstance].delegateDict.count == 0) {
        [[AVWebSocketWrapper sharedInstance] closeWebSocketConnectionRetry:NO];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:self];
}

- (void)failWithError:(NSError *)error {
    AVLoggerError(AVLoggerDomainIM, @"%@", error);
    if ([_sessionDelegate respondsToSelector:@selector(sessionFailed:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate sessionFailed:self error:error];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionError:withException:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionError:self withException:[[NSException alloc] initWithName:error.domain reason:[error.userInfo objectForKey:@"reason"] userInfo:nil]];
        });
    }
}

- (void)receiveOpened {
    if ([_sessionDelegate respondsToSelector:@selector(sessionOpened:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate sessionOpened:self];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionOpen:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionOpen:self];
        });
    }
}

- (void)receivePaused {
    if ([_sessionDelegate respondsToSelector:@selector(sessionPaused:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate sessionPaused:self];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionPaused:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionPaused:self];
        });
    }
}

- (void)receiveResumed {
    if ([_sessionDelegate respondsToSelector:@selector(sessionResumed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate sessionResumed:self];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionResumed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionResumed:self];
        });
    }
}

- (void)receiveStatus:(AVPeerStatus)status peerIds:(NSArray *)peerIds {
    if ([_sessionDelegate respondsToSelector:@selector(session:didReceiveStatus:peerIds:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate session:self didReceiveStatus:status peerIds:peerIds];
        });
    } else if (status == AVPeerStatusOffline && [_sessionDelegate respondsToSelector:@selector(onSessionStatusOffline:peers:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionStatusOffline:self peers:peerIds];
        });
        
    } else if (status == AVPeerStatusOnline && [_sessionDelegate respondsToSelector:@selector(onSessionStatusOnline:peers:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionStatusOnline:self peers:peerIds];
        });
        
    }
}

- (void)receiveMessage:(AVMessage *)message {
    if ([_sessionDelegate respondsToSelector:@selector(session:didReceiveMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate session:self didReceiveMessage:message];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionMessage:message:peerId:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionMessage:self message:message.payload peerId:message.fromPeerId];
        });
    }
}

- (void)receiveQueryResult:(NSArray *)peerIds {
    if (_queryCallbackQueue.count > 0) {
        AVArrayResultBlock block = [_queryCallbackQueue objectAtIndex:0];
        [_queryCallbackQueue removeObjectAtIndex:0];
        [AVUtils callArrayResultBlock:block array:peerIds error:nil];
    }
}

- (void)messageSendFinished:(AVMessage *)message {
    if ([_sessionDelegate respondsToSelector:@selector(session:messageSendFinished:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate session:self messageSendFinished:message];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionMessageSent:message:toPeerIds:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionMessageSent:self message:message.payload toPeerIds:@[message.toPeerId]];
        });
    }
}

- (void)messageSendFailed:(AVMessage *)message error:(NSError *)error {
    if ([_sessionDelegate respondsToSelector:@selector(session:messageSendFailed:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate session:self messageSendFailed:message error:error];
        });
    } else if ([_sessionDelegate respondsToSelector:@selector(onSessionMessageFailure:message:toPeerIds:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate onSessionMessageFailure:self message:message.payload toPeerIds:@[message.toPeerId]];
        });
    }
}

- (void)messageArrived:(AVMessage *)message {
    if ([_sessionDelegate respondsToSelector:@selector(session:messageArrived:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_sessionDelegate session:self messageArrived:message];
        });
    }
}
#pragma mark - AVSession API
- (void)openWithPeerId:(NSString *)peerId {
    [self openWithPeerId:peerId watchedPeerIds:nil];
}

- (void)openWithPeerId:(NSString *)peerId watchedPeerIds:(NSArray *)peerIds {
    dispatch_async(_sessionQueue, ^{
        if (!peerId || [peerId length] > 64) {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"PeerId should not be nil and length less than 64 characters"}];
            [self failWithError:error];
            return;
        }
        if (!_opened) {
            _opened = YES;
            _peerId = peerId;
            
            NSValue *value = [NSValue valueWithNonretainedObject:self];
            [[AVWebSocketWrapper sharedInstance].delegateDict setObject:value forKey:peerId];
            [_sessionDict setObject:self forKey:peerId];
            
            //peerIds 数组过长会导致产生的消息长度超过5000，从而导致服务器返回失败，这里将 peerIds 分割成 50 个一组，第一组在 open 的时候 watch，后面的循环遍历生成多个 add 消息完成 watch
            NSString *action = AVSessionOperationOpen;
            NSMutableArray *arrays = [[NSMutableArray alloc] init];
            NSUInteger count = peerIds.count;
            if (count > 50) {
                for (int i = 0; i < ceil(count/50.0f); ++i) {
                    NSMutableArray *watchPeerIds = [[NSMutableArray alloc] init];
                    for (int j = i*50; j < (i+1)*50 && j < count; ++j) {
                        [watchPeerIds addObject:[peerIds objectAtIndex:j]];
                    }
                    if (watchPeerIds.count > 0) {
                        [arrays addObject:watchPeerIds];
                    }
                }
            } else {
                if (peerIds) {
                    [arrays addObject:peerIds];
                }
            }
            NSArray *watchPeerIds = nil;
            if (arrays.count > 0) {
                watchPeerIds = [arrays objectAtIndex:0];
            }
            AVSignature *signature = [self signatureWithPeerIds:watchPeerIds action:action];
            
            if (signature.error) {
                [self failWithError:signature.error];
                return;
            }
            AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
            command.appId = [AVPaasClient sharedInstance].applicationId;
            command.peerId = peerId;
            command.op = action;
            command.sessionPeerIds = watchPeerIds;
            command.signature = signature;
            NSMutableArray *commands = [[NSMutableArray alloc] init];
            [commands addObject:command];
            if (command.sessionPeerIds) {
                [_watchedPeerIds addObjectsFromArray:command.sessionPeerIds];
            }

            for (int i = 1; i < arrays.count; ++i) {
                NSString *action = AVSessionOperationAdd;
                NSArray *watchPeerIds = [arrays objectAtIndex:i];
                AVSignature *signature = [self signatureWithPeerIds:watchPeerIds action:action];
                
                if (signature.error) {
                    [self failWithError:signature.error];
                    return;
                }
                
                AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
                command.peerId = _peerId;
                command.op = action;
                command.sessionPeerIds = watchPeerIds;
                command.signature = signature;
                [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                    AVSessionOutCommand *sessionOutCommand = (AVSessionOutCommand *)outCommand;
                    if (sessionOutCommand.sessionPeerIds) {
                        [_watchedPeerIds addObjectsFromArray:sessionOutCommand.sessionPeerIds];
                    }
                }];
                [commands addObject:command];
            }
            
            [[AVInstallation currentInstallation] addUniqueObject:_peerId forKey:@"channels"];
            [[AVInstallation currentInstallation] saveInBackground];
            
            if (![[AVWebSocketWrapper sharedInstance] isConnectionOpen]) {
                [[AVWebSocketWrapper sharedInstance] openWebSocketConnection];
            } else {
                for (AVCommand *command in commands) {
                    [self sendCommand:command];
                }
            }
        }
    });
}

- (void)open:(NSString *)selfId withPeerIds:(NSArray *)peerIds {
    [self openWithPeerId:selfId watchedPeerIds:peerIds];
}

- (void)watchPeerIds:(NSArray *)peerIds {
    [self watchPeerIds:peerIds callback:nil wait:YES];
}

- (void)watchPeerIds:(NSArray *)peerIds callback:(AVBooleanResultBlock)callback {
    [self watchPeerIds:peerIds callback:callback wait:NO];
}

- (void)watchPeerIds:(NSArray *)peerIds callback:(AVBooleanResultBlock)callback wait:(BOOL)wait {
    BOOL __block hasCalledBack = NO;
    dispatch_async(_sessionQueue, ^{
        if (!_paused) {
            NSString *action = AVSessionOperationAdd;
            AVSignature *signature = [self signatureWithPeerIds:peerIds action:action];
            
            if (signature.error) {
                [self failWithError:signature.error];
                hasCalledBack = YES;
                return;
            }
            
            AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
            command.peerId = _peerId;
            command.op = action;
            command.sessionPeerIds = peerIds;
            command.signature = signature;
            [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                AVSessionOutCommand *sessionOutCommand = (AVSessionOutCommand *)outCommand;
                [_watchedPeerIds addObjectsFromArray:sessionOutCommand.sessionPeerIds];
                [AVUtils callBooleanResultBlock:callback error:error];
                hasCalledBack = YES;
            }];
            [self sendCommand:command];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [AVUtils callBooleanResultBlock:callback error:error];
            if (!callback) {
                [self failWithError:error];
            }
            hasCalledBack = YES;
        }
    });
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    }
}

- (BOOL)watchPeers:(NSArray *)peerIds {
    BOOL success = NO;
    if (!_paused) {
        [self watchPeerIds:peerIds];
        success = YES;
    }
    return success;
}

- (void)unwatchPeerIds:(NSArray *)peerIds {
    [self unwatchPeerIds:peerIds callback:nil wait:YES];
}

- (void)unwatchPeerIds:(NSArray *)peerIds callback:(AVBooleanResultBlock)callback {
    [self unwatchPeerIds:peerIds callback:callback wait:NO];
}

- (void)unwatchPeerIds:(NSArray *)peerIds callback:(AVBooleanResultBlock)callback wait:(BOOL)wait {
    BOOL __block hasCalledBack = NO;
    dispatch_async(_sessionQueue, ^{
        if (!_paused) {
            NSString *action = AVSessionOperationRemove;
            AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
            command.peerId = _peerId;
            command.op = action;
            command.sessionPeerIds = peerIds;
            [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                for (NSString *peerId in peerIds) {
                    [_watchedPeerIds removeObject:peerId];
                }
                [AVUtils callBooleanResultBlock:callback error:error];
                hasCalledBack = YES;
            }];
            [self sendCommand:command];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [AVUtils callBooleanResultBlock:callback error:error];
            if (!callback) {
                [self failWithError:error];
            }
            hasCalledBack = YES;
        }
    });
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    }
}

- (void)unwatchPeers:(NSArray *)peerIds {
    [self unwatchPeerIds:peerIds];
}

- (void)sendMessage:(AVMessage *)message {
    [self sendMessage:message transient:NO];
}

- (void)sendMessage:(AVMessage *)message transient:(BOOL)transient {
    [self sendMessage:message transient:transient requestReceipt:NO];
}

- (void)sendMessage:(AVMessage *)message requestReceipt:(BOOL)requestReceipt {
    [self sendMessage:message transient:NO requestReceipt:requestReceipt];
}

- (void)sendMessage:(AVMessage *)message transient:(BOOL)transient requestReceipt:(BOOL)requestReceipt {
    dispatch_async(_sessionQueue, ^{
        AVDirectOutCommand *command = [AVDirectOutCommand commandWithMessage:message transient:transient];
        if (requestReceipt) {
            command.r = requestReceipt;
        }
        if (!transient) {
            [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                if (!error) {
                    AVDirectOutCommand *directOutCommand = (AVDirectOutCommand *)outCommand;
                    if (directOutCommand.r) {
                        AVAckCommand *ackCommand = (AVAckCommand *)inCommand;
                        NSString *uid = ackCommand.uid;
                        if (uid) {
                            [_receiptDictionary setObject:outCommand forKey:uid];
                        } else {
                            AVLoggerError(AVLoggerDomainIM, @"No uid response from server ack.");
                        }
                    }
                    [self onReceiveCommand:inCommand];
                } else {
                    [self failWithError:error];
                }
            }];
        }
        [self sendCommand:command];
    });
}

- (void)sendMessage:(NSString *)message isTransient:(BOOL)transient toPeerIds:(NSArray *)peerIds {
    for (NSString *peerId in peerIds) {
        AVMessage *messageObject = [AVMessage messageForPeerWithSession:self toPeerId:peerId payload:message];
        [self sendMessage:messageObject transient:transient];
    }
}

- (void)sendCommand:(AVCommand *)command {
    if ([command.cmd isEqualToString:AVCommandDirect]) {
        AVDirectOutCommand *outCommand = (AVDirectOutCommand *)command;
        BOOL transient = outCommand.transient;
        if (!transient) {
            [_ackTimer invalidate];
            _ackTimer = [NSTimer scheduledTimerWithTimeInterval:_messageTimeout target:self selector:@selector(ackTimerFired:) userInfo:nil repeats:NO];
            [_ackCommandQueue addObject:command];
        }
    }
    [[AVWebSocketWrapper sharedInstance] sendCommand:command];
}

- (void)ackTimerFired:(id)sender {
    if (_ackCommandQueue.count > 0) {
        [[AVWebSocketWrapper sharedInstance] closeWebSocketConnection];
    }
}

- (void)close {
    dispatch_async(_sessionQueue, ^{
        if (!_paused) {
            _opened = NO;
            NSString *action = AVSessionOperationClose;
            AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
            command.peerId = _peerId;
            command.op = action;
            [[AVWebSocketWrapper sharedInstance] sendCommand:command];
            [[AVWebSocketWrapper sharedInstance].delegateDict removeObjectForKey:_peerId];
            [_sessionDict removeObjectForKey:_peerId];
            [[AVInstallation currentInstallation] removeObject:_peerId forKey:@"channels"];
            [[AVInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if ([AVWebSocketWrapper sharedInstance].delegateDict.count == 0) {
                    [[AVWebSocketWrapper sharedInstance] closeWebSocketConnectionRetry:NO];
                }
            }];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [self failWithError:error];
        }
    });
}

- (BOOL)isOpen {
    return _opened;
}

- (BOOL)isPaused {
    return _paused;
}

- (BOOL)peerIdIsOnline:(NSString *)peerId {
    return [_onlinePeerIds containsObject:peerId];
}

- (BOOL)isOnline:(NSString *)peerId {
    return [self peerIdIsOnline:peerId];
}

- (BOOL)peerIdIsWatching:(NSString *)peerId {
    return [_watchedPeerIds containsObject:peerId];
}

- (BOOL)isWatching:(NSString *)peerId {
    return [self peerIdIsWatching:peerId];
}

- (NSString *)getSelfPeerId {
    return _peerId;
}

- (NSArray *)onlinePeerIds {
    return [_onlinePeerIds allObjects];
}

- (NSArray *)getOnlinePeers {
    return [self onlinePeerIds];
}

- (void)queryOnlinePeerIdsInPeerIds:(NSArray *)peerIds callback:(AVArrayResultBlock)callback {
    if (!callback) {
        callback = ^(NSArray *objects, NSError *error) {};
    }
    dispatch_async(_sessionQueue, ^{
        [_queryCallbackQueue addObject:callback];
        NSString *action = AVSessionOperationQuery;
        AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
        command.peerId = _peerId;
        command.op = action;
        command.sessionPeerIds = peerIds;
        [self sendCommand:command];
    });
}

- (void)getOnlinePeers:(NSArray *)peerIds withBlock:(AVArrayResultBlock)block {
    [self queryOnlinePeerIdsInPeerIds:peerIds callback:block];
}

- (NSArray *)watchedPeerIds {
    return [_watchedPeerIds allObjects];
}

- (NSArray *)getAllPeers {
    return [self watchedPeerIds];
}

- (AVGroup *)getGroup:(NSString *)groupId {
    AVGroup *group = nil;
    if (!groupId || [groupId length] == 0) {
        group = [[AVGroup alloc] initWithGroupId:nil peerId:_peerId session:self];
        [_unInitializedGroups addObject:group];
        return group;
    } else {
        return [AVGroup getGroupWithGroupId:groupId session:self];
    }
}

#pragma mark - AVWebSocketWrapperDelegate
- (void)onWebSocketOpen {
    dispatch_async(_sessionQueue, ^{
        //peerIds 数组过长会导致产生的消息长度超过5000，从而导致服务器返回失败，这里将 peerIds 分割成 50 个一组，第一组在 open 的时候 watch，后面的循环遍历生成多个 add 消息完成 watch
        NSArray *peerIds = [_watchedPeerIds allObjects];
        [_watchedPeerIds removeAllObjects];
        NSMutableArray *arrays = [[NSMutableArray alloc] init];
        NSUInteger count = peerIds.count;
        if (count > 50) {
            for (int i = 0; i < ceil(count/50.0f); ++i) {
                NSMutableArray *watchPeerIds = [[NSMutableArray alloc] init];
                for (int j = i*50; j < (i+1)*50 && j < count; ++j) {
                    [watchPeerIds addObject:[peerIds objectAtIndex:j]];
                }
                if (watchPeerIds.count > 0) {
                    [arrays addObject:watchPeerIds];
                }
            }
        } else {
            if (peerIds) {
                [arrays addObject:peerIds];
            }
        }
        NSArray *watchPeerIds = nil;
        if (arrays.count > 0) {
            watchPeerIds = [arrays objectAtIndex:0];
        }
        NSString *action = AVSessionOperationOpen;
        AVSignature *signature = [self signatureWithPeerIds:watchPeerIds action:action];
        
        if (signature.error) {
            [self failWithError:signature.error];
            return;
        }
        AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
        command.appId = [AVPaasClient sharedInstance].applicationId;
        command.peerId = _peerId;
        command.op = action;
        command.sessionPeerIds = watchPeerIds;
        command.signature = signature;
        NSMutableArray *commands = [[NSMutableArray alloc] init];
        [commands addObject:command];
        if (command.sessionPeerIds) {
            [_watchedPeerIds addObjectsFromArray:command.sessionPeerIds];
        }
        
        for (int i = 1; i < arrays.count; ++i) {
            NSString *action = AVSessionOperationAdd;
            NSArray *watchPeerIds = [arrays objectAtIndex:i];
            AVSignature *signature = [self signatureWithPeerIds:watchPeerIds action:action];
            if (signature.error) {
                [self failWithError:signature.error];
                return;
            }
            AVSessionOutCommand *command = [[AVSessionOutCommand alloc] init];
            command.peerId = _peerId;
            command.op = action;
            command.sessionPeerIds = watchPeerIds;
            command.signature = signature;
            [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                AVSessionOutCommand *sessionOutCommand = (AVSessionOutCommand *)outCommand;
                if (sessionOutCommand.sessionPeerIds) {
                    [_watchedPeerIds addObjectsFromArray:sessionOutCommand.sessionPeerIds];
                }
            }];
            [commands addObject:command];
        }
        for (AVCommand *command in commands) {
            [self sendCommand:command];
        }
//        AVSignature *signature = [self signatureWithPeerIds:[_watchedPeerIds allObjects] action:_openCommand.op];
//        if (signature.error) {
//            [self failWithError:signature.error];
//            return;
//        }
//        _openCommand.sessionPeerIds = [_watchedPeerIds allObjects];
//        _openCommand.signature = signature;
//        [self sendCommand:_openCommand];
    });
}

- (void)onWebSocketClosed {
    if (_opened) {
        _paused = YES;
        [self receivePaused];
        NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"websocket closed."}];
        if (_ackCommandQueue.count > 0) {
            AVDirectOutCommand *command = [_ackCommandQueue objectAtIndex:0];
            [_ackCommandQueue removeObjectAtIndex:0];
            AVMessage *message = command.message;
            if (message.type == AVMessageTypePeerOut) {
                [_sessionDelegate session:self messageSendFailed:message error:error];
            } else if (message.type == AVMessageTypeGroupOut) {
                NSString *groupId = message.groupId;
                AVGroup *group = [AVGroup getGroupWithGroupId:groupId session:self useDefaultDelegate:YES];
                [group messageSendFailed:message error:error];
            }
        }
        for (AVArrayResultBlock callback in _queryCallbackQueue) {
            callback(nil, error);
        }
        [_queryCallbackQueue removeAllObjects];
        [AVGroup onWebSocketClosed];
    }
}

- (void)onReceiveCommand:(AVCommand *)command {
    AVLoggerInfo(AVLoggerDomainIM, @"%@", command);
    NSString *cmd = command.cmd;
    if ([cmd isEqualToString:AVCommandPresence]) {
        [self processPresenceCommand:(AVPresenceCommand *)command];
    } else if ([cmd isEqualToString:AVCommandDirect]) {
        AVDirectInCommand *inCommand = (AVDirectInCommand *)command;
        NSString *groupId = inCommand.roomId;
        if (groupId) {
            AVGroup *group = [AVGroup getGroupWithGroupId:groupId session:self useDefaultDelegate:YES];
            [group onReceiveCommand:command];
        } else {
            [self processDirectCommand:inCommand];
        }
    } else if ([cmd isEqualToString:AVCommandSession]) {
        [self processSessionCommand:(AVSessionInCommand *)command];
    } else if ([cmd isEqualToString:AVCommandAck]) {
        [self processACKCommand:(AVAckCommand *)command];
    } else if ([cmd isEqualToString:AVCommandAckReq]) {
        [self processACKREQCommand:command];
    } else if ([cmd isEqualToString:AVCommandRoom]) {
        [self processGroupCommand:(AVRoomCommand *)command];
    } else if ([cmd isEqualToString:AVCommandRcp]) {
        [self processRcpCommand:(AVRcpCommand *)command];
    }
}

#pragma mark - generate command

- (AVSignature *)signatureWithPeerIds:(NSArray *)peerIds action:(NSString *)action {
    if ([_signatureDelegate respondsToSelector:@selector(signatureForPeerWithPeerId:watchedPeerIds:action:)]) {
        AVSignature *signature = [_signatureDelegate signatureForPeerWithPeerId:_peerId watchedPeerIds:peerIds action:action];
        return signature;
    } else if ([_sessionDelegate respondsToSelector:@selector(createSessionSignature:watchedPeerIds:action:)]) {
        AVSignature *signature = [_signatureDelegate createSessionSignature:_peerId watchedPeerIds:peerIds action:action];
        return signature;
    } else if ([_sessionDelegate respondsToSelector:@selector(createSignature:watchedPeerIds:)]) {
        AVSignature *signature = [_signatureDelegate createSignature:_peerId watchedPeerIds:peerIds];
        return signature;
    }
    return nil;
}

#pragma mark - parse or process command from server side
- (void)processPresenceCommand:(AVPresenceCommand *)command {
    NSString *statusString = command.status;
    AVPeerStatus status;
    if ([statusString isEqualToString:AVPresenceStatusOn]) {
        [_onlinePeerIds addObjectsFromArray:command.sessionPeerIds];
        status = AVPeerStatusOnline;
    } else if ([statusString isEqualToString:AVPresenceStatusOff]) {
        for (NSString *peerId in command.sessionPeerIds) {
            [_onlinePeerIds removeObject:peerId];
        }
        status = AVPeerStatusOffline;
    }
    [self receiveStatus:status peerIds:command.sessionPeerIds];
}

- (void)addMessageId:(NSString *)messageId {
    [[AVWebSocketWrapper sharedInstance] addMessageId:messageId];
}

- (BOOL)messageIdExists:(NSString *)messageId {
    return [[AVWebSocketWrapper sharedInstance] messageIdExists:messageId];
}

- (void)processDirectCommand:(AVDirectInCommand *)command {
    if (command.id && [self messageIdExists:command.id]) {
        if (![command.fromPeerId isEqualToString:_peerId]) {
            AVAckCommand *ackCommand = [[AVAckCommand alloc] init];
            ackCommand.peerId = _peerId;
            ackCommand.ids = @[command.id];
            [self sendCommand:ackCommand];
        }
        return;
    }
    if (command.id) {
        [self addMessageId:command.id];
    }
    AVMessage *message = [[AVMessage alloc] init];
    message.type = AVMessageTypePeerIn;
    message.timestamp = command.timestamp;
    message.fromPeerId = command.fromPeerId;
    message.toPeerId = command.peerId;
    message.payload = command.msg;
    message.offline = command.offline;
    [self receiveMessage:message];
    if (command.id && !command.transient && ![command.fromPeerId isEqualToString:_peerId]) {
        AVAckCommand *ackCommand = [[AVAckCommand alloc] init];
        ackCommand.peerId = _peerId;
        ackCommand.ids = @[command.id];
        [self sendCommand:ackCommand];
    }
}

- (void)processSessionCommand:(AVSessionInCommand *)command {
    NSString *op = command.op;
    
    if ([op isEqualToString:AVSessionOperationOpened]) {
        if ([self isPaused]) {
            _paused = NO;
            [self receiveResumed];
        } else {
            [self receiveOpened];
        }
        [_onlinePeerIds addObjectsFromArray:command.onlineSessionPeerIds];
        [self receiveStatus:AVPeerStatusOnline peerIds:command.onlineSessionPeerIds];
    } else if ([op isEqualToString:AVSessionOperationAdded]) {
        [_onlinePeerIds addObjectsFromArray:command.onlineSessionPeerIds];
        [self receiveStatus:AVPeerStatusOnline peerIds:command.onlineSessionPeerIds];
    } else if ([op isEqualToString:AVSessionOperationQueryResult]) {
        //        [_onlinePeerIds removeAllObjects];
        //        [_onlinePeerIds addObjectsFromArray:command.onlineSessionPeerIds];
        [self receiveQueryResult:command.onlineSessionPeerIds];
    }
}

- (void)processACKCommand:(AVAckCommand *)command {
    if (_ackCommandQueue.count > 0) {
        AVDirectOutCommand *outCommand = [_ackCommandQueue objectAtIndex:0];
        [_ackCommandQueue removeObjectAtIndex:0];
        AVMessage *message = outCommand.message;
        message.timestamp = command.t;
        if (message.type == AVMessageTypePeerOut) {
            [self messageSendFinished:message];
        } else if (message.type == AVMessageTypeGroupOut) {
            NSString *groupId = message.groupId;
            AVGroup *group = [AVGroup getGroupWithGroupId:groupId session:self useDefaultDelegate:YES];
            [group messageSendFinished:message];
        }
        
    }
}

- (void)processRcpCommand:(AVRcpCommand *)command {
    NSString *id = command.id;
    if (id) {
        AVDirectOutCommand *outCommand = [_receiptDictionary objectForKey:id];
        AVMessage *message = outCommand.message;
        message.receiptTimestamp = command.t;
        AVCommandResultBlock callback = outCommand.receiptCallback;
        [_receiptDictionary removeObjectForKey:id];
        if (callback) {
            callback(outCommand, command, nil);
            return;
        }
        if (message.type == AVMessageTypePeerOut) {
            [self messageArrived:message];
        } else {
            AVLoggerError(AVLoggerDomainIM, @"group message rcp not support");
        }
    }
    
}

- (void)processACKREQCommand:(id)message {
    //    [[AVWebSocketWrapper sharedInstance] sendMessage:[self ackCommand:message]];
}

- (void)processGroupCommand:(AVRoomCommand *)command {
    NSString *groupId = command.roomId;
    AVGroup *group = [AVGroup getGroupNoCreateWithGroupId:groupId session:self];
    if (!group && [command.byPeerId isEqualToString:_peerId]) {
        [AVGroup onReceiveGroupCreatedCommand:command];
        if ([command.op isEqualToString:AVRoomOperationJoined]) {
            if (_unInitializedGroups.count > 0) {
                group = [_unInitializedGroups firstObject];
                [_unInitializedGroups removeObject:group];
                group.groupId = groupId;
                [AVGroup addGroup:group];
                if ([group.delegate respondsToSelector:@selector(session:group:didReceiveGroupEvent:memberIds:)]) {
                    [group.delegate session:self group:group didReceiveGroupEvent:AVGroupEventSelfJoined memberIds:nil];
                }
            }
        }
    } else if (!group) {
        group = [[AVGroup alloc] initWithGroupId:groupId peerId:_peerId session:self useDefaultDelegate:YES];
        [group onReceiveCommand:command];
    } else {
        [group onReceiveCommand:command];
    }
}

#pragma clang diagnostic pop

@end
