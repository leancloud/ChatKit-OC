//
//  AVWebSocketWrapper.h
//  paas
//
//  Created by yang chaozhong on 5/14/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVCommandCommon.h"

#define PUSH_GROUP_CN @"g0"
#define PUSH_GROUP_US @"a0"

#define USE_DEBUG_SERVER 0
#define DEBUG_SERVER @"ws://puppet.leancloud.cn:5779/"

@interface AVWebSocketWrapper : NSObject

@property (nonatomic, retain) NSMutableDictionary *delegateDict;

+ (instancetype)sharedInstance;
+ (void)setDefaultPushGroup:(NSString *)pushGroup;
- (BOOL)messageIdExists:(NSString *)messageId;
- (void)addMessageId:(NSString *)messageId;
- (void)openWebSocketConnection;
- (void)closeWebSocketConnection;
- (void)closeWebSocketConnectionRetry:(BOOL)retry;
- (void)sendCommand:(AVCommand *)command;
- (void)sendMessage:(id)data;
- (void)sendPing;
- (BOOL)isConnectionOpen;
@end

@protocol AVWebSocketWrapperDelegate <NSObject>
@optional
- (void)onWebSocketOpen;
- (void)onWebSocketClosed;
- (void)onReceiveMessage:(id)message;
- (void)onReceiveCommand:(AVCommand *)command;
@end
