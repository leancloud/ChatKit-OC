//
//  AVIMWebSocketWrapper.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMCommon.h"
#import "AVIMCommandCommon.h"

#define PUSH_GROUP_CN @"g0"
#define PUSH_GROUP_US @"a0"
#define USE_DEBUG_SERVER 0
#define DEBUG_SERVER @"ws://puppet.leancloud.cn:5779/"

#define AVIM_NOTIFICATION_WEBSOCKET_ERROR @"AVIM_NOTIFICATION_WEBSOCKET_ERROR"
#define AVIM_NOTIFICATION_WEBSOCKET_OPENED @"AVIM_NOTIFICATION_WEBSOCKET_OPENED"
#define AVIM_NOTIFICATION_WEBSOCKET_CLOSED @"AVIM_NOTIFICATION_WEBSOCKET_CLOSED"
#define AVIM_NOTIFICATION_WEBSOCKET_RECONNECT @"AVIM_NOTIFICATION_WEBSOCKET_RECONNECT"
#define AVIM_NOTIFICATION_WEBSOCKET_COMMAND @"AVIM_NOTIFICATION_WEBSOCKET_COMMAND"

FOUNDATION_EXPORT NSString *const AVIMProtocolJSON1;
FOUNDATION_EXPORT NSString *const AVIMProtocolJSON2;
FOUNDATION_EXPORT NSString *const AVIMProtocolPROTOBUF1;
FOUNDATION_EXPORT NSString *const AVIMProtocolPROTOBUF2;

@interface AVIMWebSocketWrapper : NSObject

@property(nonatomic, assign) CGFloat timeout;

+ (instancetype)sharedInstance;
+ (instancetype)sharedSecurityInstance;
+ (void)setTimeoutIntervalInSeconds:(NSTimeInterval)seconds;
- (void)increaseObserverCount;
- (void)decreaseObserverCount;
- (void)openWebSocketConnection;
- (void)openWebSocketConnectionWithCallback:(AVIMBooleanResultBlock)callback;
- (void)closeWebSocketConnection;
- (void)closeWebSocketConnectionRetry:(BOOL)retry;
- (void)sendCommand:(AVIMGenericCommand *)genericCommand;
//- (void)sendMessage:(id)data;
- (void)sendPing;
- (BOOL)isConnectionOpen;
- (BOOL)messageIdExists:(NSString *)messageId;
- (void)addMessageId:(NSString *)messageId;
@end
