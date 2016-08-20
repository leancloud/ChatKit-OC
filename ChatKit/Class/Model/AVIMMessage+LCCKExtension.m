//
//  AVIMMessage+LCCKExtension.m
//  Pods
//
//  Created by 陈宜龙 on 16/8/20.
//
//

#import "AVIMMessage+LCCKExtension.h"
#import "NSObject+LCCKExtension.h"
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@implementation AVIMMessage (LCCKExtension)

- (AVIMTypedMessage *)lcck_getValidTypedMessage {
    if ([self isKindOfClass:[AVIMTypedMessage class]]) {
        return (AVIMTypedMessage *)self;
    }
    NSString *messageText;
    NSDictionary *attr;
    if ([[self class] isSubclassOfClass:[AVIMMessage class]]) {
        //当存在无法识别的自定义消息，SDK会返回 AVIMMessage 类型
        AVIMMessage *message = self;
        NSString *jsonString = message.content;
        NSDictionary *json = [jsonString lcck_JSONValue];
        do {
            NSString *customMessageDegradeKey = [json valueForKey:@"_lctext"];
            if (customMessageDegradeKey.length > 0) {
                messageText = customMessageDegradeKey;
                break;
            }
            attr = [json valueForKey:@"_lcattrs"];
            NSString *customMessageAttrDegradeKey = [attr valueForKey:LCCKCustomMessageDegradeKey];
            if (customMessageAttrDegradeKey.length > 0) {
                messageText = customMessageAttrDegradeKey;
                break;
            }
            messageText = LCCKLocalizedStrings(@"unknownMessage");
            break;
        } while (NO);
    }
    AVIMTextMessage *typedMessage = [AVIMTextMessage messageWithText:messageText attributes:attr];
    [typedMessage setValue:self.conversationId forKey:@"conversationId"];
    [typedMessage setValue:self.messageId forKey:@"messageId"];
    [typedMessage setValue:@(self.sendTimestamp) forKey:@"sendTimestamp"];
    [typedMessage setValue:self.clientId forKey:@"clientId"];
    [typedMessage lcck_setObject:@(YES) forKey:LCCKCustomMessageIsCustomKey];
    return typedMessage;
}

@end
