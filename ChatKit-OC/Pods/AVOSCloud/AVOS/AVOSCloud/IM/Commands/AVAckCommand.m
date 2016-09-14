//
//  AVAckCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVAckCommand.h"

@implementation AVAckCommand
@dynamic ids, t, uid;

- (instancetype)init {
    if ((self = [super init])) {
        self.cmd = AVCommandAck;
    }
    return self;
}
@end
