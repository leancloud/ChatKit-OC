//
//  LCIMMessageStateManager.h
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LCIMChatUntiles.h"

@interface LCIMMessageStateManager : NSObject

+ (instancetype)shareManager;


#pragma mark - Public Methods

- (LCIMMessageSendState)messageSendStateForIndex:(NSUInteger)index;
- (LCIMMessageReadState)messageReadStateForIndex:(NSUInteger)index;

- (void)setMessageSendState:(LCIMMessageSendState)messageSendState forIndex:(NSUInteger)index;
- (void)setMessageReadState:(LCIMMessageReadState)messageReadState forIndex:(NSUInteger)index;

- (void)cleanState;

@end

