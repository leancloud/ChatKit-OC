//
//  AVCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/4/14.
//
//

#import "AVCommand.h"
#import "AVCommandCommon.h"

NSString *const AVCommandPresence = @"presence";
NSString *const AVCommandDirect = @"direct";
NSString *const AVCommandSession = @"session";
NSString *const AVCommandAckReq = @"ackreq";
NSString *const AVCommandAck = @"ack";
NSString *const AVCommandRoom = @"room";
NSString *const AVCommandRcp = @"rcp";

static uint16_t _searial_id = 0;

@interface AVCommand () {
    AVCommandResultBlock _callback;
}

@end
@implementation AVCommand
@dynamic i, cmd, peerId;

+ (instancetype)commandWithJSON:(NSString *)json ioType:(AVCommandIOType)ioType {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    return [self commandWithDictionary:dict ioType:ioType];
}

+ (instancetype)commandWithDictionary:(NSDictionary *)dictionary ioType:(AVCommandIOType)ioType {
    id result = nil;
    NSString *cmd = [dictionary objectForKey:@"cmd"];
    if ([cmd isEqualToString:AVCommandPresence]) {
        result = [[AVPresenceCommand alloc] initWithDictionary:dictionary];
    } else if ([cmd isEqualToString:AVCommandDirect]) {
//        NSString *fromPeerId = [dictionary objectForKey:@"fromPeerId"];
//        NSString *toPeerIds = [dictionary objectForKey:@"toPeerIds"];
//        NSString *roomId = [dictionary objectForKey:@"roomId"];
        if (ioType == AVCommandIOTypeIn) {
            result = [[AVDirectInCommand alloc] initWithDictionary:dictionary];
        } else if (ioType == AVCommandIOTypeOut) {
            result = [[AVDirectOutCommand alloc] initWithDictionary:dictionary];
        }
    } else if ([cmd isEqualToString:AVCommandSession]) {
//        NSArray *onlineSessionPeerIds = [dictionary objectForKey:@"onlineSessionPeerIds"];
//        NSArray *sessionPeerIds = [dictionary objectForKey:@"sessionPeerIds"];
        if (ioType == AVCommandIOTypeIn) {
            result = [[AVSessionInCommand alloc] initWithDictionary:dictionary];
        } else if (ioType == AVCommandIOTypeOut) {
            result = [[AVSessionOutCommand alloc] initWithDictionary:dictionary];
        }
    } else if ([cmd isEqualToString:AVCommandAck]) {
        result = [[AVAckCommand alloc] initWithDictionary:dictionary];
    } else if ([cmd isEqualToString:AVCommandRcp]) {
        result = [[AVRcpCommand alloc] initWithDictionary:dictionary];
    } else if ([cmd isEqualToString:AVCommandRoom]) {
        result = [[AVRoomCommand alloc] initWithDictionary:dictionary];
    }
    return result;
}

+ (uint16_t)nextSerialId {
    if (_searial_id == 0) {
        ++_searial_id;
    }
    uint16_t result = _searial_id;
    _searial_id = (_searial_id + 1) % (UINT16_MAX + 1);
    return result;
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    return self;
}

- (void)addOrRefreshSerialId {
    self.i = [[self class] nextSerialId];
}

- (void)setCallback:(AVCommandResultBlock)callback {
    _callback = [callback copy];
}

- (AVCommandResultBlock)callback {
    return _callback;
}

- (NSString *)description {
    NSString *des = [[NSString alloc] initWithFormat:@"i:%hu peerId:%@ command:%@", self.i, self.peerId, self.cmd];
    return des;
//    return [self JSONString];
}
@end
