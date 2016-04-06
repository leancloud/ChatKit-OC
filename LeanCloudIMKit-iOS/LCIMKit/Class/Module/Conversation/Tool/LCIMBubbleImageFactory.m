//
//  LCIMBubbleImageFactory.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCIMBubbleImageFactory.h"
#import "LCIMConstants.h"

@implementation LCIMBubbleImageFactory

+ (UIImage *)bubbleImageViewForType:(LCIMMessageOwner)owner isHighlighted:(BOOL)isHighlighted {
    NSString *messageTypeString = @"message_";
    switch (owner) {
        case LCIMMessageOwnerSelf:
            // 发送 ==> @"MessageBubble_Sender"
            messageTypeString = [messageTypeString stringByAppendingString:@"sender_"];
            break;
        case LCIMMessageOwnerOther:
            // 接收
            messageTypeString = [messageTypeString stringByAppendingString:@"receiver_"];
            break;
            case LCIMMessageOwnerSystem:
            case LCIMMessageOwnerUnknown:
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
    return LCIM_STRETCH_IMAGE(bublleImage, bubbleImageEdgeInsets);
}

@end
