//
//  AVIMMessage.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMMessage.h"
#import "AVMPMessagePack.h"
#import "AVIMMessageObject.h"
#import "AVIMMessage_Internal.h"
/*
 {
 "cmd": "direct",
 "cid": "549bc8a5e4b0606024ec1677",
 "r": false,
 "transient": false,
 "i": 5343,
 "msg": "hello, world",
 "appId": "appid",
 "peerId": "Tom"
 }
 */

@implementation AVIMMessage

+ (instancetype)messageWithContent:(NSString *)content {
    AVIMMessage *message = [[self alloc] init];
    message.content = content;
    return message;
}

- (id)copyWithZone:(NSZone *)zone {
    AVIMMessage *message = [[self class] allocWithZone:zone];
    if (message) {
        message.status = _status;
        message.messageId = _messageId;
        message.clientId = _clientId;
        message.conversationId = _conversationId;
        message.content = _content;
        message.sendTimestamp = _sendTimestamp;
        message.deliveredTimestamp = _deliveredTimestamp;
        //        message.requestReceipt = _requestReceipt;
    }
    return message;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    AVIMMessageObject *object = [[AVIMMessageObject alloc] init];
    object.ioType = self.ioType;
    object.status = self.status;
    object.messageId = self.messageId;
    object.clientId = self.clientId;
    object.conversationId = self.conversationId;
    object.content = self.content;
    if (self.sendTimestamp != 0) {
        object.sendTimestamp = self.sendTimestamp;
    }
    if (self.deliveredTimestamp != 0) {
        object.deliveredTimestamp = self.deliveredTimestamp;
    }
    NSData *data = [object messagePack];
    [coder encodeObject:data forKey:@"data"];
    [coder encodeObject:self.localClientId forKey:NSStringFromSelector(@selector(localClientId))];
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [self init])) {
        NSData *data = [coder decodeObjectForKey:@"data"];
        AVIMMessageObject *object = [[AVIMMessageObject alloc] initWithMessagePack:data];
        self.status = object.status;
        self.messageId = object.messageId;
        self.clientId = object.clientId;
        self.conversationId = object.conversationId;
        self.content = object.content;
        self.sendTimestamp = object.sendTimestamp;
        self.deliveredTimestamp = object.deliveredTimestamp;
        self.localClientId = [coder decodeObjectForKey:NSStringFromSelector(@selector(localClientId))];
    }
    return self;
}

- (NSString *)messageId {
    return _messageId ?: (_messageId = [self tempMessageId]);
}

- (NSString *)payload {
    return self.content;
}

/* [-9223372036854775808 .. 9223372036854775807]~ */
- (NSString *)tempMessageId {
    static int64_t idx = INT64_MIN;
    return [NSString stringWithFormat:@"%lld~", idx++];
}

- (AVIMMessageIOType)ioType {
    if (!self.clientId || !self.localClientId) {
        return AVIMMessageIOTypeOut;
    }

    if ([self.clientId isEqualToString:self.localClientId]) {
        return AVIMMessageIOTypeOut;
    } else {
        return AVIMMessageIOTypeIn;
    }
}

@end
