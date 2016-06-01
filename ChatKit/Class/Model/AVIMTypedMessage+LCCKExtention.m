//
//  AVIMTypedMessage+LCCKExtention.m
//  ChatKit
//
//  Created by 陈宜龙 on 16/5/26.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "AVIMTypedMessage+LCCKExtention.h"
#import "LCCKMessage.h"

@implementation AVIMTypedMessage (LCCKExtention)

+ (AVIMTypedMessage *)lcck_messageWithLCCKMessage:(LCCKMessage *)message {
    AVIMTypedMessage *avimTypedMessage;
    switch (message.messageMediaType) {
        case LCCKMessageTypeText: {
            avimTypedMessage = [AVIMTextMessage messageWithText:message.text attributes:nil];
            break;
        }
        case LCCKMessageTypeVideo:
        case LCCKMessageTypeImage: {
            avimTypedMessage = [AVIMImageMessage messageWithText:nil attachedFilePath:message.photoPath attributes:nil];
            break;
        }
        case LCCKMessageTypeVoice: {
            avimTypedMessage = [AVIMAudioMessage messageWithText:nil attachedFilePath:message.voicePath attributes:nil];
            break;
        }
            
        case LCCKMessageTypeEmotion:
            //#import "AVIMEmotionMessage.h"
            //            avimTypedMessage = [AVIMEmotionMessage messageWithEmotionPath:message.emotionName];
            break;
            
        case LCCKMessageTypeLocation: {
            avimTypedMessage = [AVIMLocationMessage messageWithText:message.geolocations
                                                           latitude:message.location.coordinate.latitude
                                                          longitude:message.location.coordinate.longitude
                                                         attributes:nil];
            break;
        case LCCKMessageTypeSystem:
        case LCCKMessageTypeUnknow:
            //TODO:
            break;
        }
    }
    avimTypedMessage.sendTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return avimTypedMessage;
}

@end
