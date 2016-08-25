//
//  NSObject+LCCKDeallocBlockExecutor.m
//  LCCKDeallocBlockExecutor
//
//  v0.7.0 Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import "NSObject+LCCKDeallocBlockExecutor.h"
#import <objc/runtime.h>

const void * deallocExecutorBlockKey = &deallocExecutorBlockKey;

@implementation NSObject (LCCKDeallocBlockExecutor)

- (void)lcck_executeAtDealloc:(DeallocExecutorBlock)block {
    if (block) {
        LCCKDeallocExecutor *executor = [[LCCKDeallocExecutor alloc] initWithBlock:block];
        objc_setAssociatedObject(self,
                                 deallocExecutorBlockKey,
                                 executor,
                                 OBJC_ASSOCIATION_RETAIN);
    }
}

@end
