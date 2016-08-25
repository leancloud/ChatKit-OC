//
//  AVIMTypedMessage+LCCKExtension.m
//  ChatKit
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "AVIMTypedMessage+LCCKExtension.h"
#import "LCCKMessage.h"
#import "LCCKConstants.h"

@implementation AVIMTypedMessage (LCCKExtension)

- (BOOL)lcck_isSupportThisCustomMessage {
    NSNumber *typeDictKey = @([(AVIMTypedMessage *)self mediaType]);
    Class class = [_typeDict objectForKey:typeDictKey];
    return class;
}

+ (AVIMTypedMessage *)lcck_messageWithLCCKMessage:(LCCKMessage *)message {
    AVIMTypedMessage *avimTypedMessage;
    switch (message.mediaType) {
        case kAVIMMessageMediaTypeText: {
            avimTypedMessage = [AVIMTextMessage messageWithText:message.text attributes:nil];
            break;
        }
        case kAVIMMessageMediaTypeVideo:
        case kAVIMMessageMediaTypeImage: {
            avimTypedMessage = [AVIMImageMessage messageWithText:nil attachedFilePath:message.photoPath attributes:nil];
            break;
        }
        case kAVIMMessageMediaTypeAudio: {
            avimTypedMessage = [AVIMAudioMessage messageWithText:nil attachedFilePath:message.voicePath attributes:nil];
            break;
        }
        case kAVIMMessageMediaTypeLocation: {
            avimTypedMessage = [AVIMLocationMessage messageWithText:message.geolocations
                                                           latitude:message.location.coordinate.latitude
                                                          longitude:message.location.coordinate.longitude
                                                         attributes:nil];
            break;
        case kAVIMMessageMediaTypeNone:
            //TODO:
            break;
        }
    }
    avimTypedMessage.sendTimestamp = LCCK_CURRENT_TIMESTAMP;
    return avimTypedMessage;
}

- (void)lcck_setObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:object forKey:key];
    if (self.attributes == nil) {
        self.attributes = attributes;
    } else {
        [attributes addEntriesFromDictionary:self.attributes];
        self.attributes = attributes;
    }
    self.attributes = attributes;
}

@end
