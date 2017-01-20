//
//  AVIMRuntimeHelper.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/26/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMRuntimeHelper.h"
#include <objc/runtime.h>

@implementation AVIMRuntimeHelper
+ (void)invokeMethodWithTarget:(id)target method:(Method)method arguments:(NSArray *)arguments returnValue:(void *)returnValue {
//void invokeMethod(id obj, Method m, NSArray *arguments, void *returnValue) {
    id obj = target;
    Method m = method;
    char *returnType = method_copyReturnType(m);
    SEL sel = method_getName(m);
    if ([obj respondsToSelector:sel]) {
        NSMethodSignature *signature  = [obj methodSignatureForSelector:sel];
        NSInvocation      *invocation = [NSInvocation invocationWithMethodSignature:signature];
        unsigned int count = method_getNumberOfArguments(m);
        [invocation setTarget:obj];                    // index 0 (hidden)
        [invocation setSelector:sel];                  // index 1 (hidden)
        void **argLocs = malloc(sizeof(void *) * (count - 2));
        
        for (int i = 2; i < count; ++i) {
            int j = i - 2;
            id arg = [arguments objectAtIndex:j];
            char *argumentType = method_copyArgumentType(m, i);
            if (arg == [NSNull null]) {
                void *v = NULL;
                argLocs[j] = malloc(sizeof(v));
                memcpy(argLocs[j], &v, sizeof(v));
                [invocation setArgument:argLocs[j] atIndex:i];
                continue;
            }
            switch (*argumentType) {
                case '@': {
                    argLocs[j] = malloc(sizeof(arg));
                    memcpy(argLocs[j], (void*)(&arg), sizeof(arg));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'B': {
                    NSNumber *num = (NSNumber *)arg;
                    bool v = [num boolValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'c': {
                    NSNumber *num = (NSNumber *)arg;
                    char v = [num charValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 's': {
                    NSNumber *num = (NSNumber *)arg;
                    short v = [num shortValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'i': {
                    NSNumber *num = (NSNumber *)arg;
                    int v = [num intValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'l': {
                    NSNumber *num = (NSNumber *)arg;
                    long v = [num longValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'q': {
                    NSNumber *num = (NSNumber *)arg;
                    long long v = [num longLongValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'd': {
                    NSNumber *num = (NSNumber *)arg;
                    double v = [num doubleValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'f': {
                    NSNumber *num = (NSNumber *)arg;
                    float v = [num floatValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'C': {
                    NSNumber *num = (NSNumber *)arg;
                    unsigned char v = [num unsignedCharValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'S': {
                    NSNumber *num = (NSNumber *)arg;
                    unsigned short v = [num unsignedShortValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'I': {
                    NSNumber *num = (NSNumber *)arg;
                    unsigned int v = [num unsignedIntValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'L': {
                    NSNumber *num = (NSNumber *)arg;
                    unsigned long v = [num unsignedLongValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case 'Q': {
                    NSNumber *num = (NSNumber *)arg;
                    unsigned long long v = [num unsignedLongLongValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                case '^': {
                    NSValue *value = (NSValue *)arg;
                    void *v = [value pointerValue];
                    argLocs[j] = malloc(sizeof(v));
                    memcpy(argLocs[j], (void*)&v, sizeof(v));
                    [invocation setArgument:argLocs[j] atIndex:i];
                }
                    break;
                default: {
                    argLocs[j] = NULL;
                }
                    break;
            }
            free(argumentType);
        }
        [invocation invoke];
        for (int i = 2; i < count; ++i) {
            int j = i - 2;
            if (argLocs[j]) {
                free(argLocs[j]);
            }
        }
        free(argLocs);
        if (returnValue) {
            switch (*returnType) {
                case 'v': {
                    memset(returnValue, 0, sizeof(void *));
                }
                    break;
                default: {
                    [invocation getReturnValue:returnValue];
                }
                    break;
            }
        }
    } else {
        if (returnValue) {
            memset(returnValue, 0, sizeof(void *));
        }
    }
    free(returnType);
}

+ (void)callMethodWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments returnValue:(void *)returnValue {
    if ([target respondsToSelector:selector]) {
        Method m = class_getInstanceMethod([target class], selector);
        [self invokeMethodWithTarget:target method:m arguments:arguments returnValue:returnValue];
    }
}

+ (void)callMethodWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments {
    [self callMethodWithTarget:target selector:selector arguments:arguments returnValue:NULL];
}

+ (void)callMethodInMainThreadWithTarget:(id)target selector:(SEL)selector arguments:(NSArray *)arguments {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self callMethodWithTarget:target selector:selector arguments:arguments returnValue:NULL];
    });
}
@end
