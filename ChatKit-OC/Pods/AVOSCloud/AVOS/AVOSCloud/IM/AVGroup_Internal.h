//
//  AVGroup_Internal.h
//  AVOS
//
//  Created by Qihe Bian on 7/22/14.
//
//
#import <Foundation/Foundation.h>
#import "AVConstants.h"
#import "AVCommandCommon.h"

@class AVSession;
@interface AVGroup () {
    NSString *_peerId;
}
- (void)setGroupId:(NSString *)groupId;
+ (instancetype)getGroupWithGroupId:(NSString *)groupId session:(AVSession *)session useDefaultDelegate:(BOOL)useDefaultDelegate;
+ (instancetype)getGroupNoCreateWithGroupId:(NSString *)groupId session:(AVSession *)session;
+ (void)onReceiveGroupCreatedCommand:(AVRoomCommand *)command;
+ (void)onWebSocketClosed;
+ (void)addGroup:(AVGroup *)group;

- (instancetype)initWithGroupId:(NSString *)groupId peerId:(NSString *)peerId session:(AVSession *)session;
- (instancetype)initWithGroupId:(NSString *)groupId peerId:(NSString *)peerId session:(AVSession *)session useDefaultDelegate:(BOOL)useDefaultDelegate;
//- (void)onSession:(AVSession *)session groupMessage:(id)message;
//- (void)onSession:(AVSession *)session groupStatusUpdate:(id)message;

- (void)onReceiveCommand:(AVCommand *)command;
- (void)messageSendFinished:(AVMessage *)message;
- (void)messageSendFailed:(AVMessage *)message error:(NSError *)error;

@end
