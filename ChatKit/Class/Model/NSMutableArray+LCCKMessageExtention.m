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

static id const LCCKLock;

@implementation NSMutableArray (LCCKMessageExtention)

+ (NSMutableArray *)lcck_messagesWithAVIMMessages:(NSArray *)avimTypedMessage {
    NSMutableArray *messages = @[].mutableCopy;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t group = dispatch_group_create();
    //dispatch_group_notify(group, queue, ^{//..});
    NSLock *arrayLock = [[NSLock alloc] init];
    for (AVIMTypedMessage *msg in avimTypedMessage) {
        dispatch_group_async(group, queue, ^{
            LCCKMessage *lcckMsg = [LCCKMessage messageWithAVIMTypedMessage:msg];
            if (lcckMsg) {
                [arrayLock lock]; // NSMutableArray isn't thread-safe
                [messages addObject:lcckMsg];
                [arrayLock unlock];

            }
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);//doSomethingWith:
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
    NSLog(@" `self.avimTypedMessage` in `-loadOldMessages` has no object");
//    NSAssert(valid, @" `self.avimTypedMessage` in `-loadOldMessages` has no object");
    return nil;
}

@end
