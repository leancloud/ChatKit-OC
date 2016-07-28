//
//  LCCKBubbleImageFactory.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKBubbleImageFactory.h"
#import "LCCKConstants.h"
#import "UIImage+LCCKExtension.h"

@implementation LCCKBubbleImageFactory

+ (UIImage *)bubbleImageViewForType:(LCCKMessageOwnerType)owner
                        messageType:(LCCKMessageType)messageType
                      isHighlighted:(BOOL)isHighlighted {
    NSString *messageTypeString = @"message_";
    switch (messageType) {
        case LCCKMessageTypeImage:
            messageTypeString = [messageTypeString stringByAppendingString:@"image_"];
            break;
            
        default:
            break;
    }
    switch (owner) {
        case LCCKMessageOwnerTypeSelf:
            // 发送 ==> @"MessageBubble_Sender"
            messageTypeString = [messageTypeString stringByAppendingString:@"sender_"];
            break;
        case LCCKMessageOwnerTypeOther:
            // 接收
            messageTypeString = [messageTypeString stringByAppendingString:@"receiver_"];
            break;
            case LCCKMessageOwnerTypeSystem:
            case LCCKMessageOwnerTypeUnknown:
            //TODO:
            break;
    }
   
    messageTypeString = [messageTypeString stringByAppendingString:@"background_"];
    if (isHighlighted) {
        messageTypeString = [messageTypeString stringByAppendingString:@"highlight"];
    } else {
        messageTypeString = [messageTypeString stringByAppendingString:@"normal"];
    }
    UIImage *bublleImage = [UIImage lcck_imageNamed:messageTypeString bundleName:@"MessageBubble" bundleForClass:[self class]];
    UIEdgeInsets bubbleImageEdgeInsets = UIEdgeInsetsMake(30, 16, 16, 24);
    return LCCK_STRETCH_IMAGE(bublleImage, bubbleImageEdgeInsets);
}

@end
