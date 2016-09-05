//
//  AVIMBlockHelper.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/9/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMBlockHelper.h"
#import <libkern/OSAtomic.h>

#define safeBlock(first_param) \
if (block) { \
    if ([NSThread isMainThread]) { \
        block(first_param, error); \
    } else { \
        dispatch_async(dispatch_get_main_queue(), ^{ \
            block(first_param, error); \
        }); \
    } \
}

@implementation AVIMBlockHelper

+ (void)callBooleanResultBlock:(AVIMBooleanResultBlock)block
                         error:(NSError *)error
{
    safeBlock(error == nil);
}

+ (void)callIntegerResultBlock:(AVIMIntegerResultBlock)block
                        number:(NSInteger)number
                         error:(NSError *)error {
    safeBlock(number);
}

+ (void)callArrayResultBlock:(AVIMArrayResultBlock)block
                       array:(NSArray *)array
                       error:(NSError *)error {
    safeBlock(array);
}

+ (void)callConversationResultBlock:(AVIMConversationResultBlock)block
                       conversation:(AVIMConversation *)conversation
                              error:(NSError *)error {
    safeBlock(conversation);
}

+ (AVIMBooleanResultBlock)calledOnceBlockWithBooleanResultBlock:(AVIMBooleanResultBlock)block {
    __block int32_t called = 0;

    return ^(BOOL succeeded, NSError *error){
        OSAtomicAdd32(1, &called);
        if (called == 1) {
            if (block) {
                block(succeeded, error);
            }
        }
    };
}

@end
