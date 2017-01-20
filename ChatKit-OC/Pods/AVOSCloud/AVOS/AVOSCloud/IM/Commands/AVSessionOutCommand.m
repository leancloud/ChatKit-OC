//
//  AVSessionOutCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVSessionOutCommand.h"

@interface AVSessionOutCommand () {
    AVSignature *_signature;
}
@property (nonatomic, strong)NSString *s;
@property (nonatomic)int64_t t;
@property (nonatomic, strong)NSString *n;
@end
@implementation AVSessionOutCommand
@dynamic appId, sessionPeerIds, s, t, n;

- (void)setSignature:(AVSignature *)signature {
    _signature = signature;
    if (signature) {
        self.s = signature.signature;
        self.t = signature.timestamp;
        self.n = signature.nonce;
        self.sessionPeerIds = signature.signedPeerIds;
    }
}

- (AVSignature *)signature {
    return _signature;
}
@end
