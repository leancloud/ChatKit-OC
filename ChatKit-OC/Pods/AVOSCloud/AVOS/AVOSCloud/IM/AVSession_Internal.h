//
//  AVSession_Internal.h
//  AVOS
//
//  Created by Qihe Bian on 7/22/14.
//
//
#import <Foundation/Foundation.h>
#import "AVSession.h"
#import "AVWebSocketWrapper.h"
#import "AVConstants.h"
#import "AVGroup.h"
#import "AVCommandCommon.h"

#define AVIM_NOTIFICATION_WEBSOCKET_CLOSED @"AVIM_NOTIFICATION_WEBSOCKET_CLOSED_V1"

@interface AVSession()<AVWebSocketWrapperDelegate> {
//    NSString *_peerId;
    NSMutableSet *_watchedPeerIds;
    NSMutableSet *_onlinePeerIds;
    BOOL _opened;
    BOOL _paused;
    NSMutableArray *_queryCallbackQueue;
//    NSMutableArray *_messageQueue;
    NSMutableArray *_ackCommandQueue;
    AVSignature *_signatureForOpenCommand;
    NSTimer *_ackTimer;
    BOOL _ackRecieved;
//    AVGroup *_group;
//    NSMutableDictionary *_groups;
    NSMutableArray *_unInitializedGroups;
//    BOOL _isGroupSession;
//    AVSessionOutCommand *_openCommand;
    NSMutableDictionary *_receiptDictionary;
}
//@property (nonatomic, strong)NSMutableDictionary *joinedGroupsDict;
//@property (nonatomic) int sessionId;
//- (AVSignature *)generateSignature:(NSArray *)peerIds action:(NSString *)action;
//- (void)sendMessage:(NSString *)message isTransient:(BOOL)transient peerIds:(NSArray *)peerIds groupId:(NSString *)groupId;
//- (void)sendPayload:(NSString *)payload isTransient:(BOOL)transient;
+ (dispatch_queue_t)sessionQueue;
- (void)sendCommand:(AVCommand *)command;
- (void)failWithError:(NSError *)error;

@end