//
//  AVIMWebSocketWrapper.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMWebSocketWrapper.h"
#import "AVIMWebSocket.h"
#import "AVIMReachability.h"
#import "AVIMErrorUtil.h"
#import "AVIMBlockHelper.h"
#import "AVIMClient_Internal.h"
#import "AVIMUserOptions.h"
#import "AVPaasClient.h"
#import "AVOSCloud_Internal.h"
#import "LCRouter.h"
#import "SDMacros.h"

#define PING_INTERVAL 60*3
#define TIMEOUT_CHECK_INTERVAL 1

#define LCIM_OUT_COMMAND_LOG_FORMAT \
    @"\n\n" \
    @"------ BEGIN LeanCloud IM Out Command ------\n" \
    @"cmd: %@\n"                                      \
    @"type: %@\n"                                     \
    @"content: %@\n"                                     \
    @"------ END ---------------------------------\n" \
    @"\n"

#define LCIM_IN_COMMAND_LOG_FORMAT \
    @"\n\n" \
    @"------ BEGIN LeanCloud IM In Command ------\n" \
    @"content: %@\n"                                    \
    @"------ END --------------------------------\n" \
    @"\n"

static NSTimeInterval AVIMWebSocketDefaultTimeoutInterval = 15.0;

typedef enum : NSUInteger {
    //mutually exclusive
    AVIMURLQueryOptionDefault = 0,
    AVIMURLQueryOptionKeepLastValue,
    AVIMURLQueryOptionKeepFirstValue,
    AVIMURLQueryOptionUseArrays,
    AVIMURLQueryOptionAlwaysUseArrays,
    
    //can be |ed with other values
    AVIMURLQueryOptionUseArraySyntax = 8,
    AVIMURLQueryOptionSortKeys = 16
} AVIMURLQueryOptions;

NSString *const AVIMProtocolJSON1 = @"lc.json.1";
NSString *const AVIMProtocolMessagePack1 = @"lc.msgpack.1";
NSString *const AVIMProtocolPROTOBUF1 = @"lc.protobuf.1";

NSString *const AVIMProtocolJSON2 = @"lc.json.2";
NSString *const AVIMProtocolMessagePack2 = @"lc.msgpack.2";
NSString *const AVIMProtocolPROTOBUF2 = @"lc.protobuf.2";

@interface AVIMCommandCarrier : NSObject
@property(nonatomic, strong) AVIMGenericCommand *command;
@property(nonatomic)NSTimeInterval timestamp;

@end
@implementation AVIMCommandCarrier
- (void)timeoutInSeconds:(NSTimeInterval)seconds {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    timestamp += seconds;
    self.timestamp = timestamp;
}
@end

@interface AVIMWebSocketWrapper () <NSURLConnectionDelegate, AVIMWebSocketDelegate> {
    BOOL _isClosed;
    NSTimer *_pingTimer;
    NSTimer *_timeoutCheckTimer;
    NSTimer *_pingTimeoutCheckTimer;

    int _observerCount;
    int32_t _ttl;
    NSTimeInterval _lastFetchedTimestamp;
    NSTimeInterval _lastPingTimestamp;
    NSTimeInterval _lastPongTimestamp;
    NSTimeInterval _reconnectInterval;

    BOOL _waitingForPong;
    NSMutableDictionary *_commandDictionary;
    NSMutableArray *_serialIdArray;
    NSMutableArray *_messageIdArray;
}

@property (nonatomic, assign) BOOL security;
@property (nonatomic, assign) BOOL isOpening;
@property (nonatomic, assign) BOOL useSecondary;
@property (nonatomic, assign) BOOL needRetry;
@property (nonatomic, strong) NSData *routerData;
@property (nonatomic, strong) AVIMReachability *reachability;
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, strong) AVIMWebSocket *webSocket;
@property (nonatomic, copy)   AVIMBooleanResultBlock openCallback;
@property (nonatomic, strong) NSMutableDictionary *IPTable;
@property (nonatomic, copy) NSString *routerPath;

@end

@implementation AVIMWebSocketWrapper
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AVIMWebSocketWrapper *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)sharedSecurityInstance {
    static dispatch_once_t onceToken;
    static AVIMWebSocketWrapper *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.security = YES;
    });
    
    return sharedInstance;
}

+ (void)setTimeoutIntervalInSeconds:(NSTimeInterval)seconds {
    if (seconds > 0) {
        AVIMWebSocketDefaultTimeoutInterval = seconds;
    }
}

- (id)init {
    self = [super init];
    if (self) {
        //        _dataQueue = [[NSMutableArray alloc] init];
        //        _commandQueue = [[NSMutableArray alloc] init];
        _commandDictionary = [[NSMutableDictionary alloc] init];
        _serialIdArray = [[NSMutableArray alloc] init];
        _messageIdArray = [[NSMutableArray alloc] init];
        _ttl = -1;
        _lastFetchedTimestamp = -1;
        _observerCount = 0;
        _timeout = AVIMWebSocketDefaultTimeoutInterval;
        
        _lastPongTimestamp = [[NSDate date] timeIntervalSince1970];
        
        _reconnectInterval = 1;
        _isOpening = NO;
        _needRetry = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routerDidUpdate:) name:LCRouterDidUpdateNotification object:nil];

        _routerPath = [self absoluteRouterPath:[LCRouter sharedInstance].pushRouterURLString];
        
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        // Register for notification when the app shuts down
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
#else
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:NSApplicationDidResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:NSApplicationDidBecomeActiveNotification object:nil];
#endif
        [self startNotifyReachability];
    }
    return self;
}

- (void)routerDidUpdate:(NSNotification *)notification {
    self.routerPath = [self absoluteRouterPath:[LCRouter sharedInstance].pushRouterURLString];
}

- (NSString *)absoluteRouterPath:(NSString *)routerHost {
    return [[[NSURL URLWithString:routerHost] URLByAppendingPathComponent:@"v1/route"] absoluteString];
}

- (void)startNotifyReachability {
    AVIMReachability *reachability = [AVIMReachability reachabilityForInternetConnection];
    reachability.reachableOnWWAN = YES;
    reachability.reachableBlock = ^(AVIMReachability *reach) {
        [self networkDidBecomeReachable];
    };
    reachability.unreachableBlock = ^(AVIMReachability *reach) {
        [self networkDidBecomeUnreachable];
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

- (void)increaseObserverCount {
    ++_observerCount;
}

- (void)decreaseObserverCount {
    --_observerCount;
    if (_observerCount <= 0) {
        _observerCount = 0;
        [self closeWebSocketConnectionRetry:NO];
    }
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

#pragma mark - process application notification
- (void)applicationDidFinishLaunching:(id)sender {
    _messageIdArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AVIMMessageIdArray"] mutableCopy];
}

- (void)applicationDidEnterBackground:(id)sender {
    [self closeWebSocketConnectionRetry:NO];
    [[NSUserDefaults standardUserDefaults] setObject:_messageIdArray forKey:@"AVIMMessageIdArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillEnterForeground:(id)sender {
    _messageIdArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AVIMMessageIdArray"] mutableCopy];
    _reconnectInterval = 1;
    if (_reachability.isReachable && _observerCount > 0) {
        [self openWebSocketConnection];
    }
}

- (void)applicationWillResignActive:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:_messageIdArray forKey:@"AVIMMessageIdArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidBecomeActive:(id)sender {
    _messageIdArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"AVIMMessageIdArray"] mutableCopy];
}

- (void)applicationWillTerminate:(id)sender {
    [self closeWebSocketConnectionRetry:NO];
}

#pragma mark - ping timer fierd
- (void)timerFired:(id)sender {
    if (_lastPongTimestamp > 0 && [[NSDate date] timeIntervalSince1970] - _lastPongTimestamp >= 5 * 60) {
        [self closeWebSocketConnection];
        return;
    }
    
    if (_webSocket.readyState == AVIM_OPEN) {
        [self sendPing];
    }
}

+ (NSString *)URLEncodedString:(NSString *)string {
    CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (__bridge CFStringRef)string,
                                                                  NULL,
                                                                  CFSTR("!*'\"();:@&=+$,/?%#[]% "),
                                                                  kCFStringEncodingUTF8);
    return CFBridgingRelease(encoded);
}

+ (NSString *)URLQueryWithParameters:(NSDictionary *)parameters {
    return [self URLQueryWithParameters:parameters options:AVIMURLQueryOptionDefault];
}

+ (NSString *)URLQueryWithParameters:(NSDictionary *)parameters options:(AVIMURLQueryOptions)options {
    options = options ?: AVIMURLQueryOptionUseArrays;
    
    BOOL sortKeys = !!(options & AVIMURLQueryOptionSortKeys);
    if (sortKeys) {
        options -= AVIMURLQueryOptionSortKeys;
    }
    
    BOOL useArraySyntax = !!(options & AVIMURLQueryOptionUseArraySyntax);
    if (useArraySyntax) {
        options -= AVIMURLQueryOptionUseArraySyntax;
        NSAssert(options == AVIMURLQueryOptionUseArrays || options == AVIMURLQueryOptionAlwaysUseArrays,
                 @"AVIMURLQueryOptionUseArraySyntax has no effect unless combined with AVIMURLQueryOptionUseArrays or AVIMURLQueryOptionAlwaysUseArrays option");
    }
    
    NSMutableString *result = [NSMutableString string];
    NSArray *keys = [parameters allKeys];
    if (sortKeys) keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        id value = parameters[key];
        NSString *encodedKey = [self URLEncodedString:[key description]];
        if ([value isKindOfClass:[NSArray class]]) {
            if (options == AVIMURLQueryOptionKeepFirstValue && [(NSArray *)value count]) {
                if ([result length]) {
                    [result appendString:@"&"];
                }
                [result appendFormat:@"%@=%@", encodedKey, [self URLEncodedString:[[value firstObject] description]]];
            } else if (options == AVIMURLQueryOptionKeepLastValue && [(NSArray *)value count]) {
                if ([result length]) {
                    [result appendString:@"&"];
                }
                [result appendFormat:@"%@=%@", encodedKey, [self URLEncodedString:[[value lastObject] description]]];
            } else {
                for (NSString *element in value) {
                    if ([result length]) {
                        [result appendString:@"&"];
                    }
                    if (useArraySyntax) {
                        [result appendFormat:@"%@[]=%@", encodedKey, [self URLEncodedString:[element description]]];
                    } else {
                        [result appendFormat:@"%@=%@", encodedKey, [self URLEncodedString:[element description]]];
                    }
                }
            }
        } else {
            if ([result length]) {
                [result appendString:@"&"];
            }
            if (useArraySyntax && options == AVIMURLQueryOptionAlwaysUseArrays) {
                [result appendFormat:@"%@[]=%@", encodedKey, [self URLEncodedString:[value description]]];
            } else {
                [result appendFormat:@"%@=%@", encodedKey, [self URLEncodedString:[value description]]];
            }
        }
    }
    return result;
}

#pragma mark - API to use websocket

- (void)networkDidBecomeReachable {
    BOOL shouldOpen = YES;

#if TARGET_OS_IOS
    if (!getenv("LCIM_BACKGROUND_CONNECT_ENABLED") && [UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        shouldOpen = NO;
#endif

    if (shouldOpen) {
        _reconnectInterval = 1;
        [self openWebSocketConnection];
    }
}

- (void)networkDidBecomeUnreachable {
    [self closeWebSocketConnectionRetry:NO];
}

- (void)openWebSocketConnection {
    [self openWebSocketConnectionWithCallback:nil];
}

- (void)openWebSocketConnectionWithCallback:(AVIMBooleanResultBlock)callback {
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self);

        AVLoggerInfo(AVLoggerDomainIM, @"Open websocket connection.");
        self.openCallback = callback;

        if (self.isOpening) {
            AVLoggerError(AVLoggerDomainIM, @"Return because websocket is opening.");
            return;
        }

        if (!self.reachability.isReachable) {
            if (self.openCallback) {
                NSError *error = [AVIMErrorUtil errorWithCode:kAVIMErrorConnectionLost reason:@"Your device not connect to any network"];
                [AVIMBlockHelper callBooleanResultBlock:self.openCallback error:error];
                self.openCallback = nil;
            }
            return;
        }
        
        self.needRetry = YES;
        self.isOpening = YES;
        [self.reconnectTimer invalidate];
        
        if (!(self.webSocket && (self.webSocket.readyState == AVIM_OPEN || self.webSocket.readyState == AVIM_CONNECTING))) {
            if (!self.openCallback) {
                [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_RECONNECT object:self userInfo:nil];
            }

            NSData *cachedRouterData = [self cachedRouterData];

            if (cachedRouterData) {
                [self handleRouterData:cachedRouterData fromCache:YES];
                return;
            }

            NSString *appId = [AVOSCloud getApplicationId];

            if (!appId) {
                @throw [NSException exceptionWithName:@"AVOSCloudIM Exception" reason:@"Application id is nil." userInfo:nil];
            }

            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

            parameters[@"appId"] = appId;

            /*
             * iOS SDK *must* use IP address to access IM server to prevent DNS hijacking.
             * And IM server *must* issue the pinned certificate.
             */
            parameters[@"ip"] = @"true";

            if (self.security) {
                parameters[@"secure"] = @"1";
            }

            /* Back door for user to connect to puppet environment. */
            if (getenv("LC_IM_PUPPET_ENABLED") && getenv("SIMULATOR_UDID")) {
                parameters[@"debug"] = @"true";
            }

            [[AVPaasClient sharedInstance] getObject:self.routerPath withParameters:parameters block:^(id object, NSError *error) {
                NSInteger code = error.code;

                if (object && !error) { /* Everything is OK. */
                    self.useSecondary = NO;
                    NSError *JSONError = nil;
                    self.routerData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&JSONError];
                    if (!JSONError) {
                        [self handleRouterData:self.routerData fromCache:NO];
                    }
                } else if (code == 404) { /* 404, stop reconnection. */
                    self.isOpening = NO;
                    NSError *httpError = [AVIMErrorUtil errorWithCode:code reason:[NSHTTPURLResponse localizedStringForStatusCode:code]];
                    if (self.openCallback) {
                        [AVIMBlockHelper callBooleanResultBlock:self.openCallback error:httpError];
                        self.openCallback = nil;
                    } else {
                        [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:self userInfo:@{@"error": error}];
                    }
                } else if ((!object && !error) || code >= 400 || error) { /* Something error, try to reconnect. */
                    self.isOpening = NO;
                    if (!error) {
                        if (code >= 404) {
                            error = [AVIMErrorUtil errorWithCode:code reason:[NSHTTPURLResponse localizedStringForStatusCode:code]];
                        } else {
                            error = [AVIMErrorUtil errorWithCode:kAVIMErrorInvalidData reason:@"No data received"];
                        }
                    }
                    if (self.openCallback) {
                        [AVIMBlockHelper callBooleanResultBlock:self.openCallback error:error];
                        self.openCallback = nil;
                    } else {
                        [self reconnect];
                    }
                }
            }];
        }
    });
}

- (NSData *)cachedRouterData {
    if (_ttl > 0 && [[NSDate date] timeIntervalSince1970] - _lastFetchedTimestamp <= _ttl) {
        return _routerData;
    }

    return nil;
}


- (void)handleRouterData:(NSData *)data fromCache:(BOOL)fromCache {
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!error) {
        if (!fromCache) {
            _lastFetchedTimestamp = [[NSDate date] timeIntervalSince1970];
        }
        _ttl = [[dict objectForKey:@"ttl"] intValue];
        NSString *serverKey = @"server";
        if (_useSecondary) {
            serverKey = @"secondary";
        }

        /* Cache push router host if needed. */
        NSString *groupUrl = dict[@"groupUrl"];
        NSTimeInterval lastModified = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval TTL = [dict[@"ttl"] doubleValue];

        if (groupUrl && TTL) {
            /**
             美国节点返回值：
             response: {
                groupId = g0;
                groupUrl = "http://router-g0-push.leancloud.cn";
                secondary = "wss://cn-n1-cell3.leancloud.cn:6799/";
                server = "wss://rtm57.leancloud.cn:6799/";
                ttl = 3600;
             }
             
             中国节点返回值：
             response: {
                groupId = g0;
                secondary = "wss://rtm55.leancloud.cn:6799/";
                server = "wss://rtm55.leancloud.cn:6799/";
                ttl = 3600;
             }
             */
            [[LCRouter sharedInstance] cachePushRouterHostWithHost:[[NSURL URLWithString:groupUrl] host] lastModified:lastModified TTL:TTL];
        }

        /* open socket connection. */
        NSString *webSocketServer = [dict objectForKey:serverKey];
        if (webSocketServer) {
            [self internalOpenWebSocketConnection:webSocketServer];
        } else {
            [self reconnect];
        }
    } else {
        _isOpening = NO;
        if (self.openCallback) {
            [AVIMBlockHelper callBooleanResultBlock:self.openCallback error:error];
            self.openCallback = nil;
        } else {
            [self reconnect];
        }
    }
}

SecCertificateRef LCGetCertificateFromBase64String(NSString *base64);

- (NSArray *)pinnedCertificates {
    id cert = (__bridge_transfer id)LCGetCertificateFromBase64String(LCRootCertificate);
    return cert ? @[cert] : @[];
}

- (void)internalOpenWebSocketConnection:(NSString *)server {
    _webSocket.delegate = nil;
    [_webSocket close];
#if USE_DEBUG_SERVER
    server = DEBUG_SERVER;
#endif
    AVLoggerInfo(AVLoggerDomainIM, @"Open websocket with url: %@", server);
    
    NSMutableSet *protocols = [NSMutableSet set];
    NSDictionary *userOptions = [AVIMClient userOptions];

    if ([userOptions[AVIMUserOptionUseUnread] boolValue]) {
        [protocols addObject:AVIMProtocolPROTOBUF2];
    } else {
        [protocols addObject:AVIMProtocolPROTOBUF1];
    }

    if (userOptions[AVIMUserOptionCustomProtocols]) {
        [protocols removeAllObjects];
        [protocols addObjectsFromArray:userOptions[AVIMUserOptionCustomProtocols]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:server]];

    if ([protocols count]) {
        _webSocket = [[AVIMWebSocket alloc] initWithURLRequest:request protocols:[protocols allObjects]];
    } else {
        _webSocket = [[AVIMWebSocket alloc] initWithURLRequest:request];
    }

    if (self.security) {
        request.AVIM_SSLPinnedCertificates = [self pinnedCertificates];
        _webSocket.SSLPinningMode = AVIMSSLPinningModePublicKey;
    }

    _webSocket.delegate = self;
    [_webSocket open];
}

- (void)closeWebSocketConnection {
    AVLoggerInfo(AVLoggerDomainIM, @"Close websocket connection.");
    [_pingTimer invalidate];
    _isOpening = NO;
    [_webSocket close];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:self userInfo:nil];
    _isClosed = YES;
}

- (void)closeWebSocketConnectionRetry:(BOOL)retry {
    AVLoggerInfo(AVLoggerDomainIM, @"Close websocket connection.");
    [_pingTimer invalidate];
    _needRetry = retry;
    _isOpening = NO;
    [_webSocket close];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:self userInfo:nil];
    _isClosed = YES;
}

- (void)checkTimeout:(NSTimer *)timer {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (_waitingForPong && now - _lastPingTimestamp > _timeout) {
        _lastPingTimestamp = 0;
        _lastPongTimestamp = 0;
        [self closeWebSocketConnection];
        if (_pingTimeoutCheckTimer) {
            [_pingTimeoutCheckTimer invalidate];
            _pingTimeoutCheckTimer = nil;
        }
    }
    NSMutableArray *array = nil;
    for (NSNumber *num in _serialIdArray) {
        AVIMCommandCarrier *carrier = [_commandDictionary objectForKey:num];
        NSTimeInterval timestamp = carrier.timestamp;
        //        NSLog(@"now:%lf expire:%lf", now, timestamp);
        if (now > timestamp) {
            if (!array) {
                array = [[NSMutableArray alloc] init];
            }
            [array addObject:num];
            AVIMGenericCommand *command = [self dequeueCommandWithId:num];
            AVIMCommandResultBlock callback = command.callback;
            if (callback) {
                NSError *error = [AVIMErrorUtil errorWithCode:kAVIMErrorTimeout reason:@"The request timed out."];
                callback(command, nil, error);
            }
            if (now - _lastPingTimestamp > _timeout) {
                [self sendPing];
            }
        } else {
            break;
        }
    }
    if (array) {
        [_serialIdArray removeObjectsInArray:array];
    }
}

- (void)enqueueCommand:(AVIMGenericCommand *)command {
    AVIMCommandCarrier *carrier = [[AVIMCommandCarrier alloc] init];
    carrier.command = command;
    [carrier timeoutInSeconds:_timeout];
    NSNumber *num = @(command.i);
    [_commandDictionary setObject:carrier forKey:num];
    if (!_timeoutCheckTimer) {
        _timeoutCheckTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_CHECK_INTERVAL target:self selector:@selector(checkTimeout:) userInfo:nil repeats:YES];
    }
}

- (AVIMGenericCommand *)dequeueCommandWithId:(NSNumber *)num {
    AVIMCommandCarrier *carrier = [_commandDictionary objectForKey:num];
    AVIMGenericCommand *command = carrier.command;
    [_commandDictionary removeObjectForKey:num];
    if (_commandDictionary.count == 0) {
        [_timeoutCheckTimer invalidate];
        _timeoutCheckTimer = nil;
    }
    return command;
}

- (BOOL)checkSizeForData:(id)data {
    if ([data isKindOfClass:[NSString class]] && [(NSString *)data length] > 5000) {
        return NO;
    } else if ([data isKindOfClass:[NSData class]] && [(NSData *)data length] > 5000) {
        return NO;
    }
    return YES;
}

- (void)sendCommand:(AVIMGenericCommand *)genericCommand {
    AVLoggerInfo(AVLoggerDomainIM, LCIM_OUT_COMMAND_LOG_FORMAT, [AVIMCommandFormatter commandType:genericCommand.cmd], [genericCommand avim_messageClass], [genericCommand avim_description] );
    LCIMMessage *messageCommand = [genericCommand avim_messageCommand];
    BOOL needResponse = genericCommand.needResponse;
    if (messageCommand && _webSocket.readyState == AVIM_OPEN) {
        if (needResponse) {
            [genericCommand avim_addOrRefreshSerialId];
            [self enqueueCommand:genericCommand];
            NSNumber *num = @(genericCommand.i);
            [_serialIdArray addObject:num];
        }
        NSError *error = nil;
        id data = [genericCommand data];
        if (![self checkSizeForData:data]) {
            AVIMCommandResultBlock callback = genericCommand.callback;
            if (callback) {
                error = [AVIMErrorUtil errorWithCode:kAVIMErrorMessageTooLong reason:@"Message data to send is too long."];
                callback(genericCommand, nil, error);
            }
            return;
        }
        [_webSocket send:data];
        if (!needResponse) {
            AVIMCommandResultBlock callback = genericCommand.callback;
            if (callback) {
                callback(genericCommand, nil, nil);
            }
        }
    } else {
        AVIMCommandResultBlock callback = genericCommand.callback;
        NSError *error = [AVIMErrorUtil errorWithCode:kAVIMErrorConnectionLost reason:@"websocket not opened"];
        if (callback) {
            callback(genericCommand, nil, error);
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_ERROR object:self userInfo:@{@"error": error}];
        }
    }
}

- (void)sendPing {
    if ([self isConnectionOpen]) {
        AVLoggerInfo(AVLoggerDomainIM, @"Websocket send ping.");
        _lastPingTimestamp = [[NSDate date] timeIntervalSince1970];
        _waitingForPong = YES;
        if (!_pingTimeoutCheckTimer) {
            _pingTimeoutCheckTimer = [NSTimer scheduledTimerWithTimeInterval:TIMEOUT_CHECK_INTERVAL target:self selector:@selector(checkTimeout:) userInfo:nil repeats:YES];
        }
        [_webSocket sendPing:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (BOOL)isConnectionOpen {
    return _webSocket.readyState == AVIM_OPEN;
}

#pragma mark - SRWebSocketDelegate
- (void)webSocketDidOpen:(AVIMWebSocket *)webSocket {
    AVLoggerInfo(AVLoggerDomainIM, @"Websocket connection opened.");
    _isOpening = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_OPENED object:self userInfo:nil];
    
    [_reconnectTimer invalidate];
    
    [_pingTimer invalidate];
    _pingTimer = [NSTimer scheduledTimerWithTimeInterval:PING_INTERVAL target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

- (void)webSocket:(AVIMWebSocket *)webSocket didReceiveMessage:(id)message {
    _reconnectInterval = 1;
    NSError *error = nil;
    /* message for server which is in accordance with protobuf protocol must be data type, there is no need to convert string to data. */
    AVIMGenericCommand *command = [AVIMGenericCommand parseFromData:message error:&error];
    AVLoggerInfo(AVLoggerDomainIM, LCIM_IN_COMMAND_LOG_FORMAT, [command avim_description]);

    if (!command) {
        AVLoggerError(AVLoggerDomainIM, @"Not handled data.");
        return;
    }
    if (command.i > 0) {
        NSNumber *num = @(command.i);
        AVIMGenericCommand *outCommand = [self dequeueCommandWithId:num];
        if (outCommand) {
            [_serialIdArray removeObject:num];
            if ([command avim_hasError]) {
                error = [command avim_errorObject];
            }
            AVIMCommandResultBlock callback = outCommand.callback;
            if (callback) {
                callback(outCommand, command, error);
                /* 另外，对于情景：单点登录, 由于未上传 deviceToken 就 open，如果用户没有 force 登录，会报错,
                 详见 https://leanticket.cn/t/leancloud/925
                 
                 sessionMessage {
                    code: 4111
                    reason: "SESSION_CONFLICT"
                 }
                 这种情况不仅要告知用户登录失败，同时也要也要在 `-[AVIMClient processSessionCommand:]` 中统一进行异常处理，
                 触发代理方法 `-client:didOfflineWithError:` 告知用户需要将 force 设为 YES。
                 */
                if (command.hasSessionMessage && error) {
                    [self notifyCommand:command];
                }
            } else {
                [self notifyCommand:command];
            }
        } else {
            AVLoggerError(AVLoggerDomainIM, @"No out message matched the in message %@", message);
        }
    } else {
        [self notifyCommand:command];
    }
}

- (void)notifyCommand:(AVIMGenericCommand *)command {
    [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_COMMAND object:self userInfo:@{@"command": command}];
}

- (void)webSocket:(AVIMWebSocket *)webSocket didReceivePong:(id)data {
    AVLoggerInfo(AVLoggerDomainIM, @"Websocket receive pong.");
    _lastPongTimestamp = [[NSDate date] timeIntervalSince1970];
    _waitingForPong = NO;
    if (_pingTimeoutCheckTimer) {
        [_pingTimeoutCheckTimer invalidate];
        _pingTimeoutCheckTimer = nil;
    }
}

- (void)webSocket:(AVIMWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    AVLoggerDebug(AVLoggerDomainIM, @"Websocket closed with code:%ld, reason:%@.", (long)code, reason);
    _isOpening = NO;
    
    NSError *error = [AVIMErrorUtil errorWithCode:code reason:reason];
    for (NSNumber *num in _serialIdArray) {
        AVIMGenericCommand *outCommand = [self dequeueCommandWithId:num];
        if (outCommand) {
            AVIMCommandResultBlock callback = outCommand.callback;
            if (callback) {
                callback(outCommand, nil, error);
            }
        } else {
            AVLoggerError(AVLoggerDomainIM, @"No out message matched serial id %@", num);
        }
    }
    [_serialIdArray removeAllObjects];
    if (_webSocket.readyState != AVIM_CLOSED) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_CLOSED object:self userInfo:@{@"error": error}];
    }
    if ([_reachability isReachable]) {
        [self retryIfNeeded];
    }
}

- (void)forwardError:(NSError *)error forWebSocket:(AVIMWebSocket *)webSocket {
    AVLoggerError(AVLoggerDomainIM, @"Websocket open failed with error:%@.", error);

    if (_useSecondary) {
        _routerData = nil;
    } else {
        _useSecondary = YES;
    }

    _isOpening = NO;

    for (NSNumber *num in _serialIdArray) {
        AVIMGenericCommand *outCommand = [self dequeueCommandWithId:num];
        if (outCommand) {
            AVIMCommandResultBlock callback = outCommand.callback;
            if (callback) {
                callback(outCommand, nil, error);
            }
        } else {
            AVLoggerError(AVLoggerDomainIM, @"No out message matched serial id %@", num);
        }
    }

    [_serialIdArray removeAllObjects];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AVIM_NOTIFICATION_WEBSOCKET_ERROR object:self userInfo:@{@"error": error}];
    
    if (self.openCallback) {
        [AVIMBlockHelper callBooleanResultBlock:self.openCallback error:error];
        self.openCallback = nil;
    } else {
        if ([_reachability isReachable]) {
            [self retryIfNeeded];
        }
    }
}

- (BOOL)isValidIPAddress:(NSString *)address {
    if (!address)
        return NO;

    const char *str = [address UTF8String];

    struct in_addr dst;
    int success = inet_pton(AF_INET, str, &dst);

    if (success != 1) {
        struct in6_addr dst6;
        success = inet_pton(AF_INET6, str, &dst6);
    }

    return success == 1;
}

- (BOOL)shouldTryIP:(NSString *)IP forHost:(NSString *)host {
    if (!IP)
        return NO;

    NSMutableSet *IPs = self.IPTable[host];

    if (IPs) {
        if ([IPs containsObject:IP]) {
            return NO;
        } else {
            [IPs addObject:IP];
        }
    } else {
        self.IPTable[host] = [NSMutableSet setWithObject:IP];
    }

    return YES;
}

- (NSString *)selectIP:(NSArray *)IPs forHost:(NSString *)host {
    for (NSString *IP in IPs) {
        if ([self shouldTryIP:IP forHost:host]) {
            return IP;
        }
    }

    return nil;
}

- (void)webSocket:(AVIMWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self forwardError:error forWebSocket:webSocket];
}

- (NSMutableDictionary *)IPTable {
    return _IPTable ?: (_IPTable = [NSMutableDictionary dictionary]);
}

#pragma mark - reconnect

- (void)reconnect {
    AVLoggerDebug(AVLoggerDomainIM, @"Websocket connection reconnect in %ld seconds.", (long)_reconnectInterval);
    _reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:_reconnectInterval target:self selector:@selector(openWebSocketConnection) userInfo:nil repeats:NO];
    _reconnectInterval *= 2;
}

- (void)retryIfNeeded {
    if (!_needRetry) {
        return;
    }
    [self reconnect];
}

@end
