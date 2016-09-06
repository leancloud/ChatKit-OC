//
//  AVRoomCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVCommand.h"
#import "AVSignature.h"

extern NSString *const AVRoomOperationJoin;
extern NSString *const AVRoomOperationLeave;
extern NSString *const AVRoomOperationInvite;
extern NSString *const AVRoomOperationKick;
extern NSString *const AVRoomOperationJoined;
extern NSString *const AVRoomOperationReject;
extern NSString *const AVRoomOperationLeft;
extern NSString *const AVRoomOperationInvited;
extern NSString *const AVRoomOperationKicked;
extern NSString *const AVRoomOperationMembersJoined;
extern NSString *const AVRoomOperationMembersLeft;

@interface AVRoomCommand : AVCommand
@property(nonatomic, strong) NSString *op;
@property(nonatomic, strong)NSString *byPeerId;
@property(nonatomic, strong)NSString *roomId;
@property(nonatomic, strong)NSArray *roomPeerIds;
@property(nonatomic)bool transient;
//used for join,invite,kick
@property(nonatomic, strong)AVSignature *signature;
@end
