//
//  LCCKLastMessageTypeManager.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/22.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKLastMessageTypeManager.h"
#import <AVOSCloudIM/AVIMTypedMessage.h>
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKUserSystemService.h"
#import "AVIMConversation+LCCKAddition.h"

static NSMutableDictionary *attributedStringCache = nil;

@implementation LCCKLastMessageTypeManager

+ (NSString *)getMessageTitle:(AVIMTypedMessage *)message {
    NSString *title;
    switch (message.mediaType) {
        case kAVIMMessageMediaTypeText:
            title = message.text;
            break;
            
        case kAVIMMessageMediaTypeAudio:
            title = NSLocalizedStringFromTable(@"Voice", @"LCChatKitString", @"声音");
            title = [NSString stringWithFormat:@"[%@]",title];
            break;
            
        case kAVIMMessageMediaTypeImage:
            title = NSLocalizedStringFromTable(@"Photo", @"LCChatKitString", @"图片");
            title = [NSString stringWithFormat:@"[%@]",title];
            break;
            
        case kAVIMMessageMediaTypeLocation:
            title = NSLocalizedStringFromTable(@"Location", @"LCChatKitString", @"位置");
            title = [NSString stringWithFormat:@"[%@]",title];
            break;
            //TODO:
//        case kAVIMMessageMediaTypeEmotion:
//            title = NSLocalizedStringFromTable(@"Sight", @"LCChatKitString", @"表情");
//            title = [NSString stringWithFormat:@"[%@]",title];

//            break;
        case kAVIMMessageMediaTypeVideo:
            title = NSLocalizedStringFromTable(@"Video", @"LCChatKitString", @"视频");
            title = [NSString stringWithFormat:@"[%@]",title];
//TODO:
    }
    return title;
}

+ (NSAttributedString *)attributedStringWithMessage:(AVIMTypedMessage *)message conversation:(AVIMConversation *)conversation userName:(NSString *)userName {
    NSString *title = [self getMessageTitle:message];
    if (conversation.lcck_type == LCCKConversationTypeGroup) {
        title = [NSString stringWithFormat:@"%@: %@", userName, title];
    }
    if (conversation.muted && conversation.lcck_unreadCount > 0) {
        title = [NSString stringWithFormat:@"[%ld条] %@", conversation.lcck_unreadCount, title];
    }
    
    NSString *mentionText = @"[有人@你] ";
    if (conversation.lcck_draft.length > 0) {
        title = conversation.lcck_draft;
        NSString *draftText = [NSString stringWithFormat:@"[%@]", NSLocalizedStringFromTable(@"draft", @"LCChatKitString", @"草稿")];
        if (conversation.lcck_mentioned) {
            mentionText = [mentionText stringByAppendingString:draftText];
        } else {
            mentionText = draftText;
        }
    }
    
    NSString *finalText;
    if (conversation.lcck_mentioned || conversation.lcck_draft.length > 0) {
        finalText = [NSString stringWithFormat:@"%@%@", mentionText, title];
    } else {
        finalText = title;
    }
    if (finalText == nil) {
        finalText = @"";
    }
    if ([attributedStringCache objectForKey:finalText]) {
        return [attributedStringCache objectForKey:finalText];
    }
    UIFont *font = [UIFont systemFontOfSize:13];
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor grayColor], (id)NSFontAttributeName:font};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:finalText attributes:attributes];
    
    if (conversation.lcck_mentioned || conversation.lcck_draft.length > 0) {
        NSRange range = [finalText rangeOfString:mentionText];
        [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:183/255.0 green:20/255.0 blue:20/255.0 alpha:1], NSFontAttributeName : font} range:range];
    }
    
    
    [attributedStringCache setObject:attributedString forKey:finalText];
    
    return attributedString;
}

@end
