//
//  NSMutableArray+LCCKMessageExtention.h
//  ChatKit
//
// v0.5.2 Created by 陈宜龙 on 16/5/26.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (LCCKMessageExtention)

+ (NSMutableArray *)lcck_messagesWithAVIMMessages:(NSArray *)avimTypedMessage;

- (void)lcck_removeMessageAtIndex:(NSUInteger)index;

- (id)lcck_messageAtIndex:(NSUInteger)index;

@end
