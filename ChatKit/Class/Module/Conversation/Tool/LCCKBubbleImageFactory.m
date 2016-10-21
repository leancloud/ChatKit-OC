//
//  LCCKBubbleImageFactory.m
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/21.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKBubbleImageFactory.h"
#import "LCCKConstants.h"
#import "UIImage+LCCKExtension.h"
#import "LCCKSettingService.h"

@implementation LCCKBubbleImageFactory

+ (UIImage *)bubbleImageViewForType:(LCCKMessageOwnerType)owner
                        messageType:(AVIMMessageMediaType)messageMediaType
                      isHighlighted:(BOOL)isHighlighted {
    BOOL isCustomMessage = NO;
    NSString *messageTypeString = @"message_";
    switch (messageMediaType) {
        case kAVIMMessageMediaTypeImage:
        case kAVIMMessageMediaTypeLocation:
            messageTypeString = [messageTypeString stringByAppendingString:@"hollow_"];
            break;
        default:
            break;
    }
    UIEdgeInsets bubbleImageCapInsets;
    switch (owner) {
        case LCCKMessageOwnerTypeSelf: {
            // 发送
            switch (messageMediaType) {
                case kAVIMMessageMediaTypeImage:
                case kAVIMMessageMediaTypeLocation:
                    bubbleImageCapInsets = [LCCKSettingService sharedInstance].rightHollowCapMessageBubbleCustomize;
                    break;
                default:
                    bubbleImageCapInsets = [LCCKSettingService sharedInstance].rightCapMessageBubbleCustomize;
                    break;
            }
            messageTypeString = [messageTypeString stringByAppendingString:@"sender_"];
            break;
        }
        case LCCKMessageOwnerTypeOther: {
            // 接收
            switch (messageMediaType) {
                case kAVIMMessageMediaTypeImage:
                case kAVIMMessageMediaTypeLocation:
                    bubbleImageCapInsets = [LCCKSettingService sharedInstance].leftHollowCapMessageBubbleCustomize;
                    break;
                default:
                    bubbleImageCapInsets = [LCCKSettingService sharedInstance].leftCapMessageBubbleCustomize;
                    break;
            }
            messageTypeString = [messageTypeString stringByAppendingString:@"receiver_"];
            break;
        }
        case LCCKMessageOwnerTypeSystem:
            break;
        case LCCKMessageOwnerTypeUnknown:
            isCustomMessage = YES;
            break;
    }
    if (isCustomMessage) {
        return nil;
    }
    messageTypeString = [messageTypeString stringByAppendingString:@"background_"];
    if (isHighlighted) {
        messageTypeString = [messageTypeString stringByAppendingString:@"highlight"];
    } else {
        messageTypeString = [messageTypeString stringByAppendingString:@"normal"];
    }
    UIImage *bublleImage = [UIImage lcck_imageNamed:messageTypeString bundleName:@"MessageBubble" bundleForClass:[self class]];
    return LCCK_STRETCH_IMAGE(bublleImage, bubbleImageCapInsets);
}

@end
