//
//  AVMessage.m
//  AVOS
//
//  Created by Qihe Bian on 8/6/14.
//
//

#import "AVMessage.h"
#import "AVSession.h"
#import "AVGroup.h"

@implementation AVMessage

+ (AVMessage *)messageForGroup:(AVGroup *)group payload:(NSString *)payload {
    AVMessage *message = [[AVMessage alloc] init];
    message.type = AVMessageTypeGroupOut;
    message.fromPeerId = group.session.peerId;
    message.groupId = group.groupId;
    message.payload = payload;
    return message;
}

//+ (AVMessage *)messageForPeerWithSession:(AVSession *)session
//                                toPeerId:(NSString *)toPeerId
//                                 payload:(NSString *)payload {
//    return [self messageForPeerWithSession:session toPeerId:toPeerId payload:payload requestReceipt:NO];
//}

+ (AVMessage *)messageForPeerWithSession:(AVSession *)session
                                toPeerId:(NSString *)toPeerId
                                 payload:(NSString *)payload {
//                          requestReceipt:(BOOL)requestReceipt {
    AVMessage *message = [[AVMessage alloc] init];
    message.type = AVMessageTypePeerOut;
    message.fromPeerId = session.peerId;
    message.toPeerId = toPeerId;
    message.payload = payload;
//    message.requestReceipt = requestReceipt;
    return message;
}

- (id)copyWithZone:(NSZone *)zone {
    AVMessage *message = [[AVMessage alloc] init];
    if (message) {
        message.type = _type;
        message.payload = _payload;
        message.fromPeerId = _fromPeerId;
        message.toPeerId = _toPeerId;
        message.groupId = _groupId;
        message.timestamp = _timestamp;
        message.offline = _offline;
//        message.requestReceipt = _requestReceipt;
    }
    return message;
}
@end
