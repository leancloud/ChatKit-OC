//
//  NSObject+LCCKDeallocBlockExecutor.h
//  LCCKDeallocBlockExecutor
//
//  v0.7.19 Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKDeallocExecutor.h"

@interface NSObject (LCCKDeallocBlockExecutor)

- (void)lcck_executeAtDealloc:(DeallocExecutorBlock)block;

@end
