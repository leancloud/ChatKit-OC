//
//  UITableViewCell+LCCKCellIdentifier.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKCellIdentifierFactory.h"
#import "LCCKMessage.h"

@implementation LCCKCellIdentifierFactory

+ (NSString *)cellIdentifierForMessageConfiguration:(LCCKMessage *)message {
    LCCKMessageType messageType = message.messageMediaType;
    LCCKMessageOwnerType messageOwner = message.ownerType;
    LCCKConversationType messageChat = message.messageGroupType;
    NSString *identifierKey = @"LCCKChatMessageCell";
    NSString *ownerKey;
    NSString *typeKey;
    NSString *groupKey;
    switch (messageOwner) {
        case LCCKMessageOwnerTypeSystem:
            ownerKey = @"OwnerSystem";
            break;
        case LCCKMessageOwnerTypeOther:
            ownerKey = @"OwnerOther";
            break;
        case LCCKMessageOwnerTypeSelf:
            ownerKey = @"OwnerSelf";
            break;
        default:
            NSAssert(NO, @"Message Owner Unknow");
            break;
    }
    
    switch (messageType) {
        case LCCKMessageTypeVoice:
            typeKey = @"VoiceMessage";
            break;
        case LCCKMessageTypeImage:
            typeKey = @"ImageMessage";
            break;
        case LCCKMessageTypeLocation:
            typeKey = @"LocationMessage";
            break;
        case LCCKMessageTypeSystem:
            typeKey = @"SystemMessage";
            break;
        case LCCKMessageTypeText:
            typeKey = @"TextMessage";
            break;
        case LCCKMessageTypeEmotion:
        case LCCKMessageTypeVideo:
        case LCCKMessageTypeUnknow:
            //TODO:
            typeKey = @"TextMessage";
//        default:
//            NSAssert(NO, @"Message Type Unknow");
            break;
    }
    switch (messageChat) {
        case LCCKConversationTypeGroup:
            groupKey = @"GroupCell";
            break;
        case LCCKConversationTypeSingle:
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
