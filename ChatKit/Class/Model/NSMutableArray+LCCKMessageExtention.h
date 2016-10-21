//
//  NSMutableArray+LCCKMessageExtention.h
//  ChatKit
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/26.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (LCCKMessageExtention)

+ (NSMutableArray *)lcck_messagesWithAVIMMessages:(NSArray *)avimTypedMessage;

- (void)lcck_removeMessageAtIndex:(NSUInteger)index;

- (id)lcck_messageAtIndex:(NSUInteger)index;

@end
