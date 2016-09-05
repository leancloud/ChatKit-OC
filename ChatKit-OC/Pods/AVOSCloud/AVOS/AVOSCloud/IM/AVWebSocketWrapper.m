//
//  AVWebSocketWrapper.m
//  paas
//
//  Created by yang chaozhong on 5/14/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import "AVWebSocketWrapper.h"
#import "AVSRWebSocket.h"
#import "AVPaasClient.h"
#import "AVCacheManager.h"
#import "AVLogger.h"
#import "AVCommandCommon.h"
#import "AVReachability.h"
#import "AVSession_Internal.h"

#define ROUTER_SERVICE_FMT @"https://router-%@-push.leancloud.cn/v1/route"

#define PING_INTERVAL 60*3
#define kAVRouterCacheKey @"__AV_Router_Cache_Key"

static NSString *_defaultPushGroup = PUSH_GROUP_CN;
@interface AVWebSocketWrapper () <AVSRWebSocketDelegate> {
    AVSRWebSocket *_webSocket;
    BOOL _isClosed;
    NSTimer *_pingTimer;
    NSTimer *_reconnectTimer;
    AVReachability *_reachability;
    
    NSString *_currentPushGroup;
    NSInteger _ttl;
    NSInteger _lastFetchedTimestamp;
    NSInteger _lastPongTimestamp;
    
    NSInteger _reconnectInterval;
    NSMutableArray *_dataQueue;
    NSMutableArray *_commandQueue;
    BOOL _isOpening;
    BOOL _needRetry;
    BOOL _useSecondary;
    NSMutableDictionary *_commandDictionary;
    NSMutableArray *_serialIdArray;
    NSMutableDictionary *_receiptDictionary;
    NSMutableArray *_messageIdArray;
}

@end

@implementation AVWebSocketWrapper

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AVWebSocketWrapper *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (void)setDefaultPushGroup:(NSString *)pushGroup {
    _defaultPushGroup = pushGroup;
}

- (id)init {
    self = [super init];
    if (self) {
        _delegateDict = [[NSMutableDictionary alloc] init];
        _dataQueue = [[NSMutableArray alloc] init];
        _commandQueue = [[NSMutableArray alloc] init];
        _commandDictionary = [[NSMutableDictionary alloc] init];
        _serialIdArray = [[NSMutableArray alloc] init];
        _messageIdArray = [[NSMutableArray alloc] init];
        _currentPushGroup = _defaultPushGroup;
        _ttl = -1;
        _lastFetchedTimestamp = -1;
        
        _lastPongTimestamp = [[NSDate date] timeIntervalSince1970];
        
        _reconnectInterval = 1;
        _isOpening = NO;
        _needRetry = YES;
        
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        // Register for notification when the app shuts down
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
#else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:NSApplicationDidResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
#endif
        [self startNotifyReachability];
    }
    return self;
}

- (void)addMessageId:(NSString *)messageId {
    if (![_messageIdArray containsObject:messageId]) {
        [_messageIdArray addObject:messageId];
    }
    while (1) {
        if (_messageIdArray.count > 5) {
            [_messageIdArray removeObjectAtIndex:0];
        } else {
            break;
        }
    }
}

- (BOOL)messageIdExists:(NSString *)messageId {
    return [_messageIdArray containsObject:messageId];
}

- (void)startNotifyReachability {
    AVReachability *reachability = [AVReachability reachabilityForInternetConnection];
    reachability.reachableOnWWAN = YES;
    reachability.reachableBlock = ^(AVReachability *reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_reconnectInterval = 1;
            [self openWebSocketConnection];
        });
    };
    reachability.unreachableBlock = ^(AVReachability *reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self closeWebSocketConnectionRetry:NO];
        });
    };
    [reachability startNotifier];
    _reachability = reachability;
}

- (void)dealloc {
    [_reachability stopNotifier];
    if (!_isClosed) {
        [self closeWebSocketConnectionRetry:NO];
    }
}

#pragma mark - process application notification
- (void)applicationWillResignActive:(id)sender {
    [self closeWebSocketConnectionRetry:NO];
    [[NSUserDefaults standardUserDefaults] setObject:_messageIdArray forKey:@"AVMessageIdArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(id)sender {
    _messageIdArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AVMessageIdArray"] mutableCopy];
    _reconnectInterval = 1;
    if (_reachability.isReachable && _delegateDict.count > 0) {
        [self openWebSocketConnection];
    }
}

- (void)applicationWillTerminate:(id)sender {
    [self closeWebSocketConnectionRetry:NO];
}

#pragma mark - ping timer fierd
- (void)timerFired:(id)sender {
    if ([[NSDate date] timeIntervalSince1970] - _lastPongTimestamp >= 5 * 60) {
        [self reconnect];
        return;
    }
    
    if (_webSocket.readyState == AVSR_OPEN) {
        [self sendPing];
    }
}

#pragma mark - API to use websocket
- (void)openWebSocketConnection {
    AVLoggerInfo(AVLoggerDomainIM, @"Open websocket connection.");
    if (_isOpening) {
        return;
    }
    if (!_reachability.isReachable) {
        return;
    }
    if (_delegateDict.count == 0) {
        return;
    }
    _needRetry = YES;
    _isOpening = YES;
    @try {
        [_reconnectTimer invalidate];
        
        if (!(_webSocket && (_webSocket.readyState == AVSR_OPEN || _webSocket.readyState == AVSR_CONNECTING))) {
            
            if (_ttl > 0 && [[NSDate date] timeIntervalSince1970] - _lastFetchedTimestamp <= _ttl && _reconnectInterval <= 1) {
                [[AVCacheManager sharedInstance] getWithKey:kAVRouterCacheKey maxCacheAge:_ttl block:^(id object, NSError *error) {
                    if (!error) {
                        NSString *serverKey = @"server";
                        if (_useSecondary) {
                            serverKey = @"secondary";
                        }
                        NSString *server = [object objectForKey:serverKey];
                        [self internalOpenWebSocketConnection:server];
                        return;
                    } else {
                        _isOpening = NO;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self reconnect];
                        });
                    }
                }];
            }
            
            NSString *serverPath = [NSString stringWithFormat:ROUTER_SERVICE_FMT, _currentPushGroup];
            NSDictionary *parameters = @{@"appId":[AVPaasClient sharedInstance].applicationId,
                                         @"secure":@"1"};
            
            [[AVPaasClient sharedInstance] getObject:serverPath withParameters:parameters block:^(id object, NSError *error) {
                if (!error) {
                    _useSecondary = NO;
                    _ttl = [[object objectForKey:@"ttl"] integerValue];
                    _currentPushGroup = [object objectForKey:@"groupId"];
                    _lastFetchedTimestamp = [[NSDate date] timeIntervalSince1970];
                    [[AVCacheManager sharedInstance] saveJSON:object forKey:kAVRouterCacheKey];
                    
                    [self internalOpenWebSocketConnection:[object objectForKey:@"server"]];
                } else {
                    _isOpening = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self reconnect];
                    });
                }
            }];
        }
    }
    @catch (NSException *exception) {
        _reconnectInterval = 1;
        [self reconnect];
    }
}

- (void)internalOpenWebSocketConnection:(NSString *)server {
    _webSocket.delegate = nil;
    [_webSocket close];
#if USE_DEBUG_SERVER
    server = DEBUG_SERVER;
#endif
    _webSocket = [[AVSRWebSocket alloc] initWithURL:[NSURL URLWithString:server]];
    _webSocket.delegate = self;
    [_webSocket open];
}

//only use when the ackCommand is timeout
- (void)closeWebSocketConnection {
    [self closeWebSocketConnectionRetry:YES];
}

- (void)closeWebSocketConnectionRetry:(BOOL)retry {
    AVLoggerInfo(AVLoggerDomainIM, @"Close websocket connection.");
    [_pingTimer invalidate];
    _needRetry = retry;
    _isOpening = NO;
    [_webSocket close];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:nil userInfo:nil];
    _isClosed = YES;
}

- (void)sendCommand:(AVCommand *)command {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (command && _webSocket.readyState == AVSR_OPEN) {
            [command addOrRefreshSerialId];
            NSNumber *num = @(command.i);
            [_commandDictionary setObject:command forKey:num];
            [_serialIdArray addObject:num];
            AVLoggerInfo(AVLoggerDomainIM, @"Send %@.", command);
            NSString *data = [command JSONString];
            AVLoggerD(@"data:%@", data);
            [_webSocket send:data];
        } else if (command && ((_webSocket && _webSocket.readyState == AVSR_CONNECTING) || _isOpening)) {
            AVLoggerInfo(AVLoggerDomainIM, @"Send %@ delayed.", command);
            [_commandQueue addObject:command];
        } else {
            AVCommandResultBlock callback = command.callback;
            if (callback) {
                NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:0 userInfo:@{@"reason":@"websocket not opened"}];
                callback(command, nil, error);
            }
            for (NSValue *value in [_delegateDict allValues]) {
                id<AVWebSocketWrapperDelegate> delegate = [value nonretainedObjectValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate onWebSocketClosed];
                });
            }
        }
    });
}

- (void)sendMessage:(id)data {
    if (data && _webSocket.readyState == AVSR_OPEN) {
//        AVLoggerD(@"data:%@", data);
        [_webSocket send:data];
    } else if (data && _webSocket.readyState == AVSR_CONNECTING) {
        [_dataQueue addObject:data];
    }
}

- (void)sendPing {
    AVLoggerInfo(AVLoggerDomainIM, @"Websocket send ping.");
    [_webSocket sendPing];
}

- (BOOL)isConnectionOpen {
    return _webSocket.readyState == AVSR_OPEN;
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(AVSRWebSocket *)webSocket {
    AVLoggerInfo(AVLoggerDomainIM, @"Websocket connection opened.");
    _isOpening = NO;
    
    for (NSValue *value in [_delegateDict allValues]) {
        id<AVWebSocketWrapperDelegate> delegate = [value nonretainedObjectValue];
        [delegate onWebSocketOpen];
    }
    
    [_reconnectTimer invalidate];
    
    [_pingTimer invalidate];
    _pingTimer = [NSTimer scheduledTimerWithTimeInterval:PING_INTERVAL target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    NSArray *commandQueue = [_commandQueue copy];
    for (AVCommand *command in commandQueue) {
        [_commandQueue removeObject:command];
        dispatch_async([AVSession sessionQueue], ^{
            [self sendCommand:command];
        });
    }
    NSArray *queue = [_dataQueue copy];
    for (id data in queue) {
        [_dataQueue removeObject:data];
        [self sendMessage:data];
    }
}

- (void)webSocket:(AVSRWebSocket *)webSocket didReceiveMessage:(id)message {
    AVLoggerInfo(AVLoggerDomainIM, @"message:%@", message);
    _reconnectInterval = 1;
    
    NSDictionary *jsonDict = nil;
    NSError *error = nil;
    if ([message isKindOfClass:[NSString class]]) {
        NSData *data = [((NSString *)message) dataUsingEncoding:NSUTF8StringEncoding];
        jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    } else {
        jsonDict = [NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingMutableContainers error:&error];
    }
    AVCommand *command = [AVCommand commandWithDictionary:jsonDict ioType:AVCommandIOTypeIn];
    if (command.i > 0) {
        NSNumber *num = @(command.i);
        AVCommand *outCommand = [_commandDictionary objectForKey:num];
        if (outCommand) {
            [_commandDictionary removeObjectForKey:@(command.i)];
            [_serialIdArray removeObject:num];
            AVCommandResultBlock callback = outCommand.callback;
            if (callback) {
                callback(outCommand, command, nil);
                return;
            }
        } else {
            AVLoggerError(AVLoggerDomainIM, @"No out message matched the in message %@", message);
        }
    }
    NSValue *value = [_delegateDict objectForKey:command.peerId];
    id<AVWebSocketWrapperDelegate> delegate = [value nonretainedObjectValue];
    [delegate onReceiveCommand:command];
}

- (void)webSocket:(AVSRWebSocket *)webSocket didReceivePongFrame:(id)data {
    _lastPongTimestamp = [[NSDate date] timeIntervalSince1970];
}

- (void)webSocket:(AVSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    AVLoggerDebug(AVLoggerDomainIM, @"Websocket closed with code:%ld, reason:%@.", (long)code, reason);
    NSDictionary *userInfo = nil;
    if (reason) {
        userInfo = @{@"reason":reason};
    }
    _isOpening = NO;
    for (AVCommand *outCommand in _commandQueue) {
        AVCommandResultBlock callback = outCommand.callback;
        if (callback) {
            NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:code userInfo:userInfo];
            callback(outCommand, nil, error);
        }
    }
    [_commandQueue removeAllObjects];
    [_dataQueue removeAllObjects];
    for (NSNumber *num in _serialIdArray) {
        AVCommand *outCommand = [_commandDictionary objectForKey:num];
        if (outCommand) {
            [_commandDictionary removeObjectForKey:num];
            AVCommandResultBlock callback = outCommand.callback;
            if (callback) {
                NSError *error = [NSError errorWithDomain:@"AVOSCloudIM" code:code userInfo:userInfo];
                callback(outCommand, nil, error);
            }
        } else {
            AVLoggerError(AVLoggerDomainIM, @"No out message matched serial id %@", num);
        }
    }
    [_serialIdArray removeAllObjects];
    for (NSValue *value in [_delegateDict allValues]) {
        id<AVWebSocketWrapperDelegate> delegate = [value nonretainedObjectValue];
        [delegate onWebSocketClosed];
    }
    if ([_reachability isReachable]) {
        [self reconnect];
    }
}

- (void)webSocket:(AVSRWebSocket *)webSocket didFailWithError:(NSError *)error {
    AVLoggerError(AVLoggerDomainIM, @"Websocket open failed with error:%@.", error);
    _isOpening = NO;
    if (_useSecondary) {
        [[AVCacheManager sharedInstance] clearCacheForKey:kAVRouterCacheKey];
    } else {
        _useSecondary = YES;
    }
    for (AVCommand *outCommand in _commandQueue) {
        AVCommandResultBlock callback = outCommand.callback;
        if (callback) {
            callback(outCommand, nil, error);
        }
    }
    [_commandQueue removeAllObjects];
    [_dataQueue removeAllObjects];
    for (NSNumber *num in _serialIdArray) {
        AVCommand *outCommand = [_commandDictionary objectForKey:num];
        if (outCommand) {
            [_commandDictionary removeObjectForKey:num];
            AVCommandResultBlock callback = outCommand.callback;
            if (callback) {
                callback(outCommand, nil, error);
            }
        } else {
            AVLoggerError(AVLoggerDomainIM, @"No out message matched serial id %@", num);
        }
    }
    [_serialIdArray removeAllObjects];
    for (NSValue *value in [_delegateDict allValues]) {
        id<AVWebSocketWrapperDelegate> delegate = [value nonretainedObjectValue];
        [delegate onWebSocketClosed];
    }
    if ([_reachability isReachable]) {
        [self reconnect];
    }
}

#pragma mark - reconnect
- (void)reconnect {
    if (!_needRetry) {
        return;
    }
    AVLoggerDebug(AVLoggerDomainIM, @"Websocket connection reconnect in %ld seconds.", (long)_reconnectInterval);
    _reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:_reconnectInterval target:self selector:@selector(openWebSocketConnection) userInfo:nil repeats:NO];
    _reconnectInterval *= 2;
}

@end
