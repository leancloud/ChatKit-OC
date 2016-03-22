//
//  LCIMMessageStateManager.m
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMMessageStateManager.h"

@interface LCIMMessageStateManager ()

@property (nonatomic, strong) NSMutableDictionary *messageReadStateDict;
@property (nonatomic, strong) NSMutableDictionary *messageSendStateDict;

@end

@implementation LCIMMessageStateManager

+ (instancetype)shareManager {
    static id manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if ([super init]) {
        _messageReadStateDict = [NSMutableDictionary dictionary];
        _messageSendStateDict = [NSMutableDictionary dictionary];
    }
    return self;
}


#pragma mark - Public Methods

- (LCIMMessageSendState)messageSendStateForIndex:(NSUInteger)index {
    if (_messageSendStateDict[@(index)]) {
        return [_messageSendStateDict[@(index)] integerValue];
    }
    return LCIMMessageSendStateSuccess;
}

- (LCIMMessageReadState)messageReadStateForIndex:(NSUInteger)index {
    if (_messageReadStateDict[@(index)]) {
        return [_messageReadStateDict[@(index)] integerValue];
    }
    return LCIMMessageReaded;
}

- (void)setMessageSendState:(LCIMMessageSendState)messageSendState forIndex:(NSUInteger)index {
    _messageSendStateDict[@(index)] = @(messageSendState);
}

- (void)setMessageReadState:(LCIMMessageReadState)messageReadState forIndex:(NSUInteger)index {
    _messageReadStateDict[@(index)] = @(messageReadState);
}


- (void)cleanState {
    
    [_messageSendStateDict removeAllObjects];
    [_messageReadStateDict removeAllObjects];
    
}

@end
