//
//  CYLDeallocExecutor.m
//  CYLDeallocExecutor
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLDeallocExecutor.h"

@interface CYLDeallocExecutor()

@property (nonatomic, copy) CYLDeallocExecutorBlock deallocExecutorBlock;

@end

@implementation CYLDeallocExecutor

- (id)initWithBlock:(CYLDeallocExecutorBlock)deallocExecutorBlock {
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
