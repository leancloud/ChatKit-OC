//
//  LCCKBubbleImageFactory.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKBubbleImageFactory.h"
#import "LCCKConstants.h"

@implementation LCCKBubbleImageFactory

+ (UIImage *)bubbleImageViewForType:(LCCKMessageOwner)owner isHighlighted:(BOOL)isHighlighted {
    NSString *messageTypeString = @"message_";
    switch (owner) {
        case LCCKMessageOwnerSelf:
            // 发送 ==> @"MessageBubble_Sender"
            messageTypeString = [messageTypeString stringByAppendingString:@"sender_"];
            break;
        case LCCKMessageOwnerOther:
            // 接收
            messageTypeString = [messageTypeString stringByAppendingString:@"receiver_"];
            break;
            case LCCKMessageOwnerSystem:
            case LCCKMessageOwnerUnknown:
            //TODO:
            break;
    }
    messageTypeString = [messageTypeString stringByAppendingString:@"background_"];
    if (isHighlighted) {
        messageTypeString = [messageTypeString stringByAppendingString:@"highlight"];
    } else {
        messageTypeString = [messageTypeString stringByAppendingString:@"normal"];
    }
    NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"MessageBubble.bundle/%@", messageTypeString];
    UIImage *bublleImage = [UIImage imageNamed:imageNameWithBundlePath];
    UIEdgeInsets bubbleImageEdgeInsets = UIEdgeInsetsMake(30, 16, 16, 24);
    return LCCK_STRETCH_IMAGE(bublleImage, bubbleImageEdgeInsets);
}

@end
