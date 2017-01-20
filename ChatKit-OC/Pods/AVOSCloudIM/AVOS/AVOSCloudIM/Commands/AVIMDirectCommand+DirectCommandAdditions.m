//
//  AVIMDirectCommand+DirectCommandAdditions.m
//  AVOS
//
//  Created by 陈宜龙 on 16/1/8.
//  Copyright © 2016年 LeanCloud Inc. All rights reserved.
//

#import "AVIMDirectCommand+DirectCommandAdditions.h"
#import <objc/runtime.h>

@implementation AVIMDirectCommand (DirectCommandAdditions)

- (AVIMMessage *)message {
    return objc_getAssociatedObject(self, @selector(message));
}

- (void)setMessage:(AVIMMessage *)message {
    objc_setAssociatedObject(self, @selector(message), message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
