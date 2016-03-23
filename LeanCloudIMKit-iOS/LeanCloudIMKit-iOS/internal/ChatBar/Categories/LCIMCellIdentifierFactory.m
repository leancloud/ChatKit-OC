//
//  UITableViewCell+LCIMCellIdentifier.m
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMCellIdentifierFactory.h"
#import "LCIMMessage.h"

@implementation LCIMCellIdentifierFactory

+ (NSString *)cellIdentifierForMessageConfiguration:(LCIMMessage *)message {
    LCIMMessageType messageType = message.messageMediaType;
    LCIMMessageOwner messageOwner = message.bubbleMessageType;
    LCIMMessageChat messageChat = message.messageGroupType;
    NSString *identifierKey = @"LCIMChatMessageCell";
    NSString *ownerKey;
    NSString *typeKey;
    NSString *groupKey;
    switch (messageOwner) {
        case LCIMMessageOwnerSystem:
            ownerKey = @"OwnerSystem";
            break;
        case LCIMMessageOwnerOther:
            ownerKey = @"OwnerOther";
            break;
        case LCIMMessageOwnerSelf:
            ownerKey = @"OwnerSelf";
            break;
        default:
            NSAssert(NO, @"Message Owner Unknow");
            break;
    }
    
    switch (messageType) {
        case LCIMMessageTypeVoice:
            typeKey = @"VoiceMessage";
            break;
        case LCIMMessageTypeImage:
            typeKey = @"ImageMessage";
            break;
        case LCIMMessageTypeLocation:
            typeKey = @"LocationMessage";
            break;
        case LCIMMessageTypeSystem:
            typeKey = @"SystemMessage";
            break;
        case LCIMMessageTypeText:
            typeKey = @"TextMessage";
            break;
            case LCIMMessageTypeEmotion:
            case LCIMMessageTypeVideo:
            //TODO:
            typeKey = @"TextMessage";
//        default:
//            NSAssert(NO, @"Message Type Unknow");
            break;
    }
    switch (messageChat) {
        case LCIMMessageChatGroup:
            groupKey = @"GroupCell";
            break;
        case LCIMMessageChatSingle:
            groupKey = @"SingleCell";
            break;
        default:
            groupKey = @"";
            break;
    }
    NSString *cellIdentifier = [NSString stringWithFormat:@"%@_%@_%@_%@",identifierKey,ownerKey,typeKey,groupKey];
    return cellIdentifier;
}


@end
