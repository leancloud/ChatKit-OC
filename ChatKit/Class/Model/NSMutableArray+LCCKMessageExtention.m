//
//  NSMutableArray+LCCKMessageExtention.m
//  ChatKit
//
//  Created by 陈宜龙 on 16/5/26.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "NSMutableArray+LCCKMessageExtention.h"
#import "AVIMTypedMessage+LCCKExtention.h"
#import "LCCKMessage.h"

@implementation NSMutableArray (LCCKMessageExtention)

+ (NSMutableArray *)lcck_messagesWithAVIMMessages:(NSArray *)avimTypedMessage {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (AVIMTypedMessage *msg in avimTypedMessage) {
        LCCKMessage *lcckMsg = [LCCKMessage messageWithAVIMTypedMessage:msg];
        if (lcckMsg) {
            [messages addObject:lcckMsg];
        }
    }
    return messages;
}

- (void)lcck_removeMessageAtIndex:(NSUInteger)index {
    if (index < self.count) {
        [self removeObjectAtIndex:index];
    }
}

- (id)lcck_messageAtIndex:(NSUInteger)index {
    BOOL valid = (index < self.count);
    if (index < self.count) {
        return self[index];
    }
    NSAssert(valid, @" `self.avimTypedMessage` in `-loadOldMessages` has no object");
    return nil;
}

@end
