//
//  LCCKDeallocExecutor.h
//  LCCKDeallocExecutor
//
//  v0.7.0 Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 15/12/27.
//  Copyright © 2015年 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DeallocExecutorBlock)(void);

@interface LCCKDeallocExecutor : NSObject

- (id)initWithBlock:(DeallocExecutorBlock)block;

@end
