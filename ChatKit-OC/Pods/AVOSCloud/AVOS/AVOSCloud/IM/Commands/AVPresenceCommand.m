//
//  AVPresenceCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/5/14.
//
//

#import "AVPresenceCommand.h"
NSString *const AVPresenceStatusOn = @"on";
NSString *const AVPresenceStatusOff = @"off";

@implementation AVPresenceCommand
@dynamic sessionPeerIds, status;

- (instancetype)init {
    if ((self = [super init])) {
        self.cmd = AVCommandPresence;
    }
    return self;
}
@end
