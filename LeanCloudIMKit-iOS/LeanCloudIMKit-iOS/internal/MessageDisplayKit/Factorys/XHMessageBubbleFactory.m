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
            messageTypeString = @"WC_";
            break;
            case XHBubbleImageViewStyleCustome:
            messageTypeString = @"";
    }
    switch (type) {
        case XHBubbleMessageTypeSending:
            // 发送 ==> @"MessageBubble_Sender"
            messageTypeString = [messageTypeString stringByAppendingString:@"MessageBubble_Sender"];
            break;
        case XHBubbleMessageTypeReceiving:
            // 接收
            messageTypeString = [messageTypeString stringByAppendingString:@"MessageBubble_Receiver"];
            break;
    }
    switch (mediaType) {
        case XHBubbleMessageMediaTypePhoto:
        case XHBubbleMessageMediaTypeVideo:
            messageTypeString = [messageTypeString stringByAppendingString:@""];
            break;
        case XHBubbleMessageMediaTypeText:
        case XHBubbleMessageMediaTypeVoice:
        case XHBubbleMessageMediaTypeEmotion:
        case XHBubbleMessageMediaTypeLocalPosition:
            messageTypeString = [messageTypeString stringByAppendingString:@""];
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
            edgeInsets = UIEdgeInsetsMake(30, 16, 16, 24);
            break;
        case XHBubbleImageViewStyleCustome:
            edgeInsets = UIEdgeInsetsMake(30, 28, 85, 28);
            break;
    }
    return edgeInsets;
}

@end
