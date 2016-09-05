//
//  AVDirectOutCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVDirectOutCommand.h"

@interface AVDirectOutCommand () {
    AVCommandResultBlock _receiptCallback;
}
@end

@implementation AVDirectOutCommand
@dynamic toPeerIds, transient, r;

- (void)addOrRefreshSerialId {
    if (!self.transient) {
        self.i = [[self class] nextSerialId];
    }
}

- (void)setReceiptCallback:(AVCommandResultBlock)callback {
    _receiptCallback = [callback copy];
}

- (AVCommandResultBlock)receiptCallback {
    return _receiptCallback;
}
@end
