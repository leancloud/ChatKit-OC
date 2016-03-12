//
//  XHMessageBubbleFactory.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-4-25.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "XHMessageBubbleFactory.h"
#import "XHMacro.h"

@implementation XHMessageBubbleFactory

+ (UIImage *)bubbleImageViewForType:(XHBubbleMessageType)type
                              style:(XHBubbleImageViewStyle)style
                          meidaType:(XHBubbleMessageMediaType)mediaType {
    NSString *messageTypeString;
    
    switch (style) {
        case XHBubbleImageViewStyleWeChat:
            // 类似微信的
            messageTypeString = @"MessageBubble";
            break;
        default:
            break;
    }
    
    switch (type) {
        case XHBubbleMessageTypeSending:
            // 发送 ==> @"weChatBubble_Sending_LeanChat"
            messageTypeString = [messageTypeString stringByAppendingString:@"_Sender"];
            break;
        case XHBubbleMessageTypeReceiving:
            // 接收
            messageTypeString = [messageTypeString stringByAppendingString:@"_Receiver"];
            break;
        default:
            break;
    }
    
    switch (mediaType) {
        case XHBubbleMessageMediaTypePhoto:
        case XHBubbleMessageMediaTypeVideo:
            messageTypeString = [messageTypeString stringByAppendingString:@""];
            break;
        case XHBubbleMessageMediaTypeText:
        case XHBubbleMessageMediaTypeVoice:
            messageTypeString = [messageTypeString stringByAppendingString:@""];
            break;
        default:
            break;
    }
    
    NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"MessageBubble.bundle/%@", messageTypeString];
    UIImage *bublleImage = [UIImage imageNamed:imageNameWithBundlePath];
    
    UIEdgeInsets bubbleImageEdgeInsets = [self bubbleImageEdgeInsetsWithStyle:style];
    return XH_STRETCH_IMAGE(bublleImage, bubbleImageEdgeInsets);
}

+ (UIEdgeInsets)bubbleImageEdgeInsetsWithStyle:(XHBubbleImageViewStyle)style {
    UIEdgeInsets edgeInsets;
    switch (style) {
        case XHBubbleImageViewStyleWeChat:
            // 类似微信的
            edgeInsets = UIEdgeInsetsMake(30, 28, 85, 28);
            break;
        default:
            break;
    }
    return edgeInsets;
}

@end
