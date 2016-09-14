//
//  AVRoomCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVRoomCommand.h"

NSString *const AVRoomOperationJoin = @"join";
NSString *const AVRoomOperationLeave = @"leave";
NSString *const AVRoomOperationInvite = @"invite";
NSString *const AVRoomOperationKick = @"kick";
NSString *const AVRoomOperationJoined = @"joined";
NSString *const AVRoomOperationReject = @"reject";
NSString *const AVRoomOperationLeft = @"left";
NSString *const AVRoomOperationInvited = @"invited";
NSString *const AVRoomOperationKicked = @"kicked";
NSString *const AVRoomOperationMembersJoined = @"members-joined";
NSString *const AVRoomOperationMembersLeft = @"members-left";

@interface AVRoomCommand () {
    AVSignature *_signature;
}
@property (nonatomic, strong)NSString *s;
@property (nonatomic)int64_t t;
@property (nonatomic, strong)NSString *n;
@end

@implementation AVRoomCommand
@dynamic op, byPeerId, roomId, roomPeerIds, s, t, n, transient;

- (instancetype)init {
    if ((self = [super init])) {
        self.cmd = AVCommandRoom;
    }
    return self;
}

- (void)setSignature:(AVSignature *)signature {
    _signature = signature;
    if (signature) {
        self.s = signature.signature;
        self.t = signature.timestamp;
        self.n = signature.nonce;
    }
}

- (AVSignature *)signature {
    return _signature;
}

- (NSString *)description {
    NSString *des = [[NSString alloc] initWithFormat:@"%@ operation:%@", [super description], self.op];
    return des;
}

@end
