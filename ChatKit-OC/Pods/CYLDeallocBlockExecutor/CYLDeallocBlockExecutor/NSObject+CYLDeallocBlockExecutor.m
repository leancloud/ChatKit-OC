//
//  NSObject+CYLDeallocBlockExecutor.m
//  CYLDeallocBlockExecutor
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import "NSObject+CYLDeallocBlockExecutor.h"
#import <objc/runtime.h>

const void *CYLDeallocExecutorsKey = &CYLDeallocExecutorsKey;

@implementation NSObject (CYLDeallocBlockExecutor)

- (NSHashTable *)cyl_deallocExecutors {
    
    NSHashTable *table = objc_getAssociatedObject(self,CYLDeallocExecutorsKey);
    
    if (!table) {
        table = [NSHashTable hashTableWithOptions:NSPointerFunctionsStrongMemory];
        objc_setAssociatedObject(self, CYLDeallocExecutorsKey, table, OBJC_ASSOCIATION_RETAIN);
    }
    
    return table;
}


- (void)cyl_executeAtDealloc:(CYLDeallocExecutorBlock)block {
    if (block) {
        CYLDeallocExecutor *executor = [[CYLDeallocExecutor alloc] initWithBlock:block];
        
        @synchronized (self) {
            [[self cyl_deallocExecutors] addObject:executor];
        }
    }
}

@end
