//
//  LCCKDeallocExecutor.m
//  LCCKDeallocExecutor
//
//  v0.7.19 Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import "LCCKDeallocExecutor.h"

@interface LCCKDeallocExecutor()

@property (nonatomic, copy) DeallocExecutorBlock deallocExecutorBlock;

@end

@implementation LCCKDeallocExecutor

- (id)initWithBlock:(DeallocExecutorBlock)deallocExecutorBlock {
    self = [super init];
    if (self) {
        _deallocExecutorBlock = [deallocExecutorBlock copy];
    }
    return self;
}

- (void)dealloc {
    _deallocExecutorBlock ? _deallocExecutorBlock() : nil;
}

@end
