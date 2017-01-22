//
//  AVIMConversationOutCommand.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/8/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMConversationOutCommand.h"
#import "AVIMSignature.h"

@interface AVIMConversationOutCommand () {
    AVIMSignature *_signature;
}
@property (nonatomic, strong) NSString *s;
@property (nonatomic, assign) int64_t   t;
@property (nonatomic, strong) NSString *n;
@end

@implementation AVIMConversationOutCommand

@dynamic i, cmd, code, appCode, reason, peerId, needResponse, callback, op, cid, m, transient, muted, s, t, n, signature, attr, where, sort, skip, limit, unique, option;

- (void)setSignature:(AVIMSignature *)signature {
    _signature = signature;
    if (signature) {
        self.s = signature.signature;
        self.t = signature.timestamp;
        self.n = signature.nonce;
    }
}

- (AVIMSignature *)signature {
    return _signature;
}

@end
