//
//  NSObject+CYLDeallocBlockExecutor.h
//  CYLDeallocBlockExecutor
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLDeallocExecutor.h"

@interface NSObject (CYLDeallocBlockExecutor)

- (void)cyl_executeAtDealloc:(CYLDeallocExecutorBlock)block;

@end
