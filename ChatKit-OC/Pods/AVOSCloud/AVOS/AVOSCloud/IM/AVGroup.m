//
//  AVGroup.m
//  AVOS
//
//  Created by Qihe Bian on 7/22/14.
//
//

#import "AVGroup.h"
#import "AVGroup_Internal.h"
#import "AVPaasClient.h"
#import "AVSession.h"
#import "AVSession_Internal.h"
#import "AVSignature.h"
#import "AVUtils.h"

static NSMutableArray *_createGroupCallbacks = nil;
static NSMutableDictionary *_groupDict = nil;
static id<AVGroupDelegate> _defaultDelegate = nil;

@interface _GroupCallbackContext : NSObject
@property(nonatomic,strong)AVGroupResultBlock callback;
@property(nonatomic,weak)id<AVGroupDelegate> delegate;
@end
@implementation _GroupCallbackContext


@end
@implementation AVGroup

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSString *)keyForGroupId:(NSString *)groupId session:(AVSession *)session {
    NSString *result = [[NSString alloc] initWithFormat:@"%@:%@", groupId, session.peerId];
    return result;
}

+ (AVSignature *)signatureWithPeerId:(NSString *)peerId groupId:(NSString *)groupId peerIds:(NSArray *)peerIds action:(NSString *)action {
    AVSession *session = [AVSession getSessionWithPeerId:peerId];
    if ([session.signatureDelegate respondsToSelector:@selector(signatureForGroupWithPeerId:groupId:groupPeerIds:action:)]) {
        AVSignature *signature = [session.signatureDelegate signatureForGroupWithPeerId:peerId groupId:groupId groupPeerIds:peerIds action:action];
        return signature;
    } else if ([session.signatureDelegate respondsToSelector:@selector(createGroupSignature:groupId:groupPeerIds:action:)]) {
        AVSignature *signature = [session.signatureDelegate createGroupSignature:peerId groupId:groupId groupPeerIds:peerIds action:action];
        return signature;
    } else if ([session.signatureDelegate respondsToSelector:@selector(createGroupSignature:groupPeerIds:action:)]) {
        AVSignature *signature = [session.signatureDelegate createGroupSignature:peerId groupPeerIds:peerIds action:action];
        return signature;
    }
    return nil;
}

+ (void)createGroupWithSession:(AVSession *)session groupDelegate:(id<AVGroupDelegate>)groupDelegate callback:(AVGroupResultBlock)callback {
    [self createGroupWithSession:session groupDelegate:groupDelegate options:AVGroupOptionNone callback:callback];
}

+ (void)createGroupWithSession:(AVSession *)session
                 groupDelegate:(id<AVGroupDelegate>)groupDelegate
                       options:(AVGroupOption)options
                      callback:(AVGroupResultBlock)callback {
    if (!callback) {
        callback = ^(AVGroup *group, NSError *error) {};
    }
    dispatch_async([AVSession sessionQueue], ^{
        bool transient = options & AVGroupOptionTransient;
        NSString *action = AVRoomOperationJoin;
        AVSignature *signature = [self signatureWithPeerId:session.peerId groupId:nil peerIds:nil action:action];
        
        if (signature.error) {
            [session failWithError:signature.error];
            return;
        }
        
        AVRoomCommand *command = [[AVRoomCommand alloc] init];
        command.op = action;
        command.peerId = session.peerId;
        command.signature = signature;
        if (transient) {
            command.transient = YES;
        }
        if (!_createGroupCallbacks) {
            _createGroupCallbacks = [[NSMutableArray alloc] init];
        }
        _GroupCallbackContext *context = [[_GroupCallbackContext alloc] init];
        context.callback = callback;
        context.delegate = groupDelegate;
        [_createGroupCallbacks addObject:context];
        [session sendCommand:command];
    });
}

+ (AVGroup *)getGroupWithGroupId:(NSString *)groupId session:(AVSession *)session {
    return [self getGroupWithGroupId:groupId session:session useDefaultDelegate:NO];
}

+ (AVGroup *)getGroupWithGroupId:(NSString *)groupId session:(AVSession *)session useDefaultDelegate:(BOOL)useDefaultDelegate {
    if (!groupId || !session) {
        return nil;
    }
    NSString *key = [self keyForGroupId:groupId session:session];
    AVGroup *group = [_groupDict objectForKey:key];
    if (!group) {
        group = [[AVGroup alloc] initWithGroupId:groupId peerId:session.peerId session:session useDefaultDelegate:useDefaultDelegate];
    } else {
        group.session = session;
    }
    return group;
}

+ (AVGroup *)getGroupNoCreateWithGroupId:(NSString *)groupId session:(AVSession *)session {
    NSString *key = [self keyForGroupId:groupId session:session];
    AVGroup *group = [_groupDict objectForKey:key];
    group.session = session;
    return group;
}

+ (void)onReceiveGroupCreatedCommand:(AVRoomCommand *)command {
    if (_createGroupCallbacks.count > 0) {
        _GroupCallbackContext *context = [_createGroupCallbacks objectAtIndex:0];
        AVGroupResultBlock callback = context.callback;
        id<AVGroupDelegate> delegate = context.delegate;
        [_createGroupCallbacks removeObjectAtIndex:0];
        AVGroup *group = [[AVGroup alloc] initWithGroupId:command.roomId peerId:command.peerId session:[AVSession getSessionWithPeerId:command.peerId]];
        group.delegate = delegate;
        callback(group, nil);
    }
}

+ (void)onWebSocketClosed {
    NSArray *contexts = [_createGroupCallbacks copy];
    NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"websocket closed."}];
    
    for (_GroupCallbackContext *context in contexts) {
        [_createGroupCallbacks removeObject:context];
        AVGroupResultBlock callback = context.callback;
        callback(nil, error);
    }
}

+ (void)addGroup:(AVGroup *)group {
    NSString *key = [self keyForGroupId:group.groupId session:group.session];
    [_groupDict setObject:group forKey:key];
}

+ (void)setDefaultDelegate:(id<AVGroupDelegate>)delegate {
    _defaultDelegate = delegate;
}

- (void)setGroupId:(NSString *)groupId {
    _groupId = groupId;
}

- (instancetype)initWithGroupId:(NSString *)groupId peerId:(NSString *)peerId session:(AVSession *)session {
    return [self initWithGroupId:groupId peerId:peerId session:session useDefaultDelegate:NO];
}

- (instancetype)initWithGroupId:(NSString *)groupId peerId:(NSString *)peerId session:(AVSession *)session useDefaultDelegate:(BOOL)useDefaultDelegate {
    if ((self = [super init])) {
        if (!_groupDict) {
            _groupDict = [[NSMutableDictionary alloc] init];
        }
        _groupId = groupId;
        _peerId = peerId;
        _session = session;
        NSString *key = [[self class] keyForGroupId:groupId session:session];
        [_groupDict setObject:self forKey:key];
        if (useDefaultDelegate) {
            _delegate = _defaultDelegate;
        }
    }
    return self;
}

- (void)sendCommand:(AVCommand *) command {
    [_session sendCommand:command];
}

- (void)join {
    dispatch_async([AVSession sessionQueue], ^{
        if (!_session.isPaused) {
            NSString *key = [[self class] keyForGroupId:_groupId session:_session];
            [_groupDict setObject:self forKey:key];
            
            NSString *action = AVRoomOperationJoin;
            AVSignature *signature = [self signatureWithPeerIds:nil action:action];
            
            if (signature.error) {
                [_session failWithError:signature.error];
                return;
            }
            
            AVRoomCommand *command = [[AVRoomCommand alloc] init];
            command.peerId = _peerId;
            command.roomId = _groupId;
            command.op = action;
            command.signature = signature;
            [self sendCommand:command];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [_session failWithError:error];
        }
    });
}

- (void)sendMessage:(AVMessage *)message {
    [self sendMessage:message transient:NO];
}

- (void)sendMessage:(AVMessage *)message transient:(BOOL)transient {
    AVDirectOutCommand *command = [AVDirectOutCommand commandWithMessage:message transient:transient];
    [self sendCommand:command];
}

- (void)sendMessage:(NSString *)message isTransient:(BOOL)transient {
    AVMessage *messageObject = [AVMessage messageForGroup:self payload:message];
    [self sendMessage:messageObject transient:transient];
}

- (void)kickPeerIds:(NSArray *)peerIds {
    [self kickPeerIds:peerIds callback:nil];
}

- (void)kickPeerIds:(NSArray *)peerIds callback:(AVArrayResultBlock)callback {
    dispatch_async([AVSession sessionQueue], ^{
        if (!_session.isPaused) {
            NSString *action = AVRoomOperationKick;
            AVSignature *signature = [self signatureWithPeerIds:peerIds action:action];
            
            if (signature.error) {
                [_session failWithError:signature.error];
                return;
            }
            
            AVRoomCommand *command = [[AVRoomCommand alloc] init];
            command.peerId = _peerId;
            command.roomId = _groupId;
            command.op = action;
            command.signature = signature;
            command.roomPeerIds = peerIds;
            [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                AVRoomCommand *roomCommand = (AVRoomCommand *)inCommand;
                if (callback) {
                    [AVUtils callArrayResultBlock:callback array:roomCommand.roomPeerIds error:error];
                } else {
                    [self processRoomCommand:roomCommand];
                }
            }];
            [self sendCommand:command];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [AVUtils callArrayResultBlock:callback array:nil error:error];
            if (!callback) {
                [_session failWithError:error];
            }
        }
    });
}

- (BOOL)kick:(NSArray *)peerIds {
    BOOL success = NO;
    if (!_session.isPaused) {
        [self kickPeerIds:peerIds];
        success = YES;
    }
    return success;
}

- (void)invitePeerIds:(NSArray *)peerIds {
    [self invitePeerIds:peerIds callback:nil];
}

- (void)invitePeerIds:(NSArray *)peerIds callback:(AVArrayResultBlock)callback {
    dispatch_async([AVSession sessionQueue], ^{
        if (!_session.isPaused) {
            NSString *action = AVRoomOperationInvite;
            AVSignature *signature = [self signatureWithPeerIds:peerIds action:action];
            
            if (signature.error) {
                [_session failWithError:signature.error];
                return;
            }
            
            AVRoomCommand *command = [[AVRoomCommand alloc] init];
            command.peerId = _peerId;
            command.roomId = _groupId;
            command.op = action;
            command.signature = signature;
            command.roomPeerIds = peerIds;
            [command setCallback:^(AVCommand *outCommand, AVCommand *inCommand, NSError *error) {
                AVRoomCommand *roomCommand = (AVRoomCommand *)inCommand;
                if (callback) {
                    [AVUtils callArrayResultBlock:callback array:roomCommand.roomPeerIds error:error];
                } else {
                    [self processRoomCommand:roomCommand];
                }
            }];
            [self sendCommand:command];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [AVUtils callArrayResultBlock:callback array:nil error:error];
            if (!callback) {
                [_session failWithError:error];
            }
        }
    });
}

- (BOOL)invite:(NSArray *)peerIds {
    BOOL success = NO;
    if (!_session.isPaused) {
        [self invitePeerIds:peerIds];
        success = YES;
    }
    return success;
}

- (void)quit {
    dispatch_async([AVSession sessionQueue], ^{
        if (!_session.isPaused) {
            NSString *action = AVRoomOperationLeave;
            AVRoomCommand *command = [[AVRoomCommand alloc] init];
            command.peerId = _peerId;
            command.roomId = _groupId;
            command.op = action;
            [self sendCommand:command];
        } else {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"session paused."}];
            [_session failWithError:error];
        }
    });
}

- (void)receiveEvent:(AVGroupEvent)event peerIds:(NSArray *)peerIds {
    if ([_delegate respondsToSelector:@selector(group:didReceiveEvent:peerIds:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate group:self didReceiveEvent:event peerIds:peerIds];
        });
    } else if ([_delegate respondsToSelector:@selector(session:group:didReceiveGroupEvent:memberIds:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate session:_session group:self didReceiveGroupEvent:event memberIds:peerIds];
        });
        
    }
}

- (void)receiveMessage:(AVMessage *)message {
    if ([_delegate respondsToSelector:@selector(group:didReceiveMessage:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate group:self didReceiveMessage:message];
        });
    } else if ([_delegate respondsToSelector:@selector(session:group:didReceiveGroupMessage:fromPeerId:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate session:_session group:self didReceiveGroupMessage:message.payload fromPeerId:message.fromPeerId];
        });
        
    }
}

- (void)messageSendFinished:(AVMessage *)message {
    if ([_delegate respondsToSelector:@selector(group:messageSendFinished:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate group:self messageSendFinished:message];
        });
    } else if ([_delegate respondsToSelector:@selector(session:group:messageSent:success:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate session:_session group:self messageSent:message.payload success:YES];
        });
    }
}

- (void)messageSendFailed:(AVMessage *)message error:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(group:messageSendFailed:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate group:self messageSendFailed:message error:error];
        });
    } else if ([_delegate respondsToSelector:@selector(session:group:messageSent:success:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate session:_session group:self messageSent:message.payload success:NO];
        });
    }
}

- (AVSignature *)signatureWithPeerIds:(NSArray *)peerIds action:(NSString *)action {
    return [[self class] signatureWithPeerId:_peerId groupId:_groupId peerIds:peerIds action:action];
}

- (void)onReceiveCommand:(AVCommand *)command {
    NSString *cmd = command.cmd;
    if ([cmd isEqualToString:AVCommandDirect]) {
        AVDirectInCommand *inCommand = (AVDirectInCommand *)command;
        [self processDirectCommand:inCommand];
    } else if ([cmd isEqualToString:AVCommandRoom]) {
        [self processRoomCommand:(AVRoomCommand *)command];
    }
}

- (void)addMessageId:(NSString *)messageId {
    [[AVWebSocketWrapper sharedInstance] addMessageId:messageId];
}

- (BOOL)messageIdExists:(NSString *)messageId {
    return [[AVWebSocketWrapper sharedInstance] messageIdExists:messageId];
}

- (void)processDirectCommand:(AVDirectInCommand *)command {
    if (command.id && [self messageIdExists:command.id]) {
        if (![command.fromPeerId isEqualToString:_session.peerId]) {
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
    message.type = AVMessageTypeGroupIn;
    message.timestamp = command.timestamp;
    message.fromPeerId = command.fromPeerId;
    message.toPeerId = command.peerId;
    message.groupId = command.roomId;
    message.payload = command.msg;
    message.offline = command.offline;
    [self receiveMessage:message];
    if (command.id && ![command.fromPeerId isEqualToString:_session.peerId]) {
        AVAckCommand *ackCommand = [[AVAckCommand alloc] init];
        ackCommand.peerId = _peerId;
        ackCommand.ids = @[command.id];
        [self sendCommand:ackCommand];
    }
}

- (void)processRoomCommand:(AVRoomCommand *)command {
    NSString *operation = command.op;
    AVGroupEvent event;
    if ([operation isEqualToString:AVRoomOperationJoined]) {
        event = AVGroupEventSelfJoined;
    } else if ([operation isEqualToString:AVRoomOperationReject]) {
        event = AVGroupEventReject;
    } else if ([operation isEqualToString:AVRoomOperationLeft]) {
        event = AVGroupEventSelfLeft;
    } else if ([operation isEqualToString:AVRoomOperationInvited]) {
        event = AVGroupEventMemberInvited;
    } else if ([operation isEqualToString:AVRoomOperationKicked]) {
        event = AVGroupEventMemberKicked;
    } else if ([operation isEqualToString:AVRoomOperationMembersJoined]) {
        event = AVGroupEventMemberJoined;
    } else if ([operation isEqualToString:AVRoomOperationMembersLeft]) {
        event = AVGroupEventMemberLeft;
    }
    [self receiveEvent:event peerIds:command.roomPeerIds];
}

#pragma clang diagnostic pop

@end
