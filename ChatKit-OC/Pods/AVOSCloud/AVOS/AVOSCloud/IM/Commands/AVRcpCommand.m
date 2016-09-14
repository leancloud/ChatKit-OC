//
//  AVRcpCommand.m
//  AVOS
//
//  Created by Qihe Bian on 11/5/14.
//
//

#import "AVRcpCommand.h"

@implementation AVRcpCommand
@dynamic id, t;

- (instancetype)init {
    if ((self = [super init])) {
        self.cmd = AVCommandRcp;
    }
    return self;
}
@end
