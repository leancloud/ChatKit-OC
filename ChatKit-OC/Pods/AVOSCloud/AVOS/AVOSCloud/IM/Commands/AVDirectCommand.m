//
//  AVDirectCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/5/14.
//
//

#import "AVDirectCommand.h"
#import "AVCommandCommon.h"

@implementation AVDirectCommand
@dynamic msg, roomId, transient;

+ (instancetype)commandWithMessage:(AVMessage *)message transient:(BOOL)transient{
    AVMessageType type = message.type;
    id result = nil;
    switch (type) {
        case AVMessageTypePeerOut: {
            AVDirectOutCommand *r = [[AVDirectOutCommand alloc] init];
            r.peerId = message.fromPeerId;
            r.toPeerIds = @[message.toPeerId];
            r.msg = message.payload;
            r.transient = transient;
            r.message = message;
            result = r;
        }
            break;
        case AVMessageTypeGroupOut: {
            AVDirectOutCommand *r = [[AVDirectOutCommand alloc] init];
            r.peerId = message.fromPeerId;
            r.roomId = message.groupId;
            r.msg = message.payload;
            r.transient = transient;
            r.message = message;
            result = r;
        }
            break;
            
        default:
            break;
    }
    return result;
}


- (instancetype)init {
    if ((self = [super init])) {
        self.cmd = AVCommandDirect;
    }
    return self;
}

- (NSString *)description {
    NSString *des = [[NSString alloc] initWithFormat:@"%@ message:%@", [super description], self.msg];
    return des;
}
@end
