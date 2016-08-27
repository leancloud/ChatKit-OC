//
//  NSObject+LCCKExtension.m
//  Pods
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/8/10.
//
//

#import "NSObject+LCCKExtension.h"

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@implementation NSObject (LCCKExtension)

- (BOOL)lcck_isCustomMessage {
    return [self lcck_isCustomTypedMessage];
}

- (BOOL)lcck_isCustomTypedMessage {
    BOOL isCustomMessage = NO;
    if ([[self class] isSubclassOfClass:[AVIMTypedMessage class]]) {
        if ((int)[(AVIMTypedMessage *)self mediaType] > 0) {
            isCustomMessage = YES;
        }
    }
    return isCustomMessage;
}

- (BOOL)lcck_isCustomLCCKMessage {
    BOOL isCustomMessage = NO;
    int mediaType = (int)[(LCCKMessage *)self mediaType];
    if ( mediaType >= 0) {
        isCustomMessage = YES;
    }
    return isCustomMessage;
}

- (NSTimeInterval)lcck_messageTimestamp {
    NSTimeInterval selfMessageTimestamp;
    if ([self lcck_isCustomMessage]) {
        NSTimeInterval sendTime = [(AVIMTypedMessage *)self sendTimestamp];
        //如果当前消息是正在发送的消息，则没有时间戳
        if (sendTime == 0) {
            sendTime = LCCK_CURRENT_TIMESTAMP;
        }
        selfMessageTimestamp = sendTime;
    } else {
        selfMessageTimestamp = [(LCCKMessage *)self timestamp];
    }
    return selfMessageTimestamp;
}

// 是否显示时间轴Label
- (void)lcck_shouldDisplayTimestampForMessages:(NSArray *)messages callback:(LCCKShouldDisplayTimestampCallBack)callback {
    /* Set LCCKIsDebugging=1 in preprocessor macros under build settings to enable debugging.*/
#ifdef LCCKIsDebugging
    //如果定义了LCCKIsDebugging则执行从这里到#endif的代码
    return YES;
#endif
    BOOL containsMessage= [messages containsObject:self];
    if (!containsMessage) {
        return;
    }
    
    NSTimeInterval selfMessageTimestamp = [self lcck_messageTimestamp];
    
    NSUInteger index = [messages indexOfObject:self];
    if (index == 0) {
        !callback ?: callback(YES, selfMessageTimestamp);
        return;
    }
    id lastMessage = [messages objectAtIndex:index - 1];
    
    NSTimeInterval lastMessageTimestamp = [lastMessage lcck_messageTimestamp];
    NSTimeInterval interval = (selfMessageTimestamp - lastMessageTimestamp) / 1000;
    
    int limitInterval = 60 * 3;
    if (interval > limitInterval) {
        !callback ?: callback(YES, selfMessageTimestamp);
        return;
    }
    !callback ?: callback(NO, selfMessageTimestamp);
}

- (NSDictionary *)lcck_JSONValue {
    if (!self) { return nil; }
    id result = nil;
    NSError* error = nil;
    if ([self isKindOfClass:[NSString class]]) {
        if ([(NSString *)self length] == 0) { return nil; }
        NSData *dataToBeParsed = [(NSString *)self dataUsingEncoding:NSUTF8StringEncoding];
        result = [NSJSONSerialization JSONObjectWithData:dataToBeParsed options:kNilOptions error:&error];
    } else {
        result = [NSJSONSerialization JSONObjectWithData:(NSData *)self options:kNilOptions error:&error];
    }
    if (![result isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return result;
}

@end
