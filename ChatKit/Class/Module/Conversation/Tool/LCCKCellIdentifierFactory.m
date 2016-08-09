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

+ (NSString *)cellIdentifierForMessageConfiguration:(LCCKMessage *)message conversationType:(LCCKConversationType)conversationType {
    LCCKMessageType messageType = message.messageMediaType;
    LCCKMessageOwnerType messageOwner = message.ownerType;
    NSString *identifierKey = @"LCCKChatMessageCell";
    NSString *ownerKey;
    NSString *typeKey;
    NSString *groupKey;

    
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
    switch (conversationType) {
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
    
    switch (messageOwner) {
        case LCCKMessageOwnerTypeSystem:
            ownerKey = @"OwnerSystem";
            break;
        case LCCKMessageOwnerTypeOther:
            ownerKey = @"OwnerOther";
            break;
        case LCCKMessageOwnerTypeSelf:
            ownerKey = @"OwnerSelf";
            groupKey = @"SingleCell";
            break;
        default:
            NSAssert(NO, @"Message Owner Unknow");
            break;
    }
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"%@_%@_%@_%@",identifierKey,ownerKey,typeKey,groupKey];
    return cellIdentifier;
}


@end
