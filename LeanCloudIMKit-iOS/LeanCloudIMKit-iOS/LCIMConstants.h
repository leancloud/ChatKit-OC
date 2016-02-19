//
//  LCIMConstants.h
//  LeanCloudIMKit-iOS
//
//  Created by EloncChan on 16/2/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  common typdef and constants, and so on.

typedef void (^LCIMBoolCallBack)(BOOL succeed, NSError *error);

#define safeBlock(first_param)\
if (callback) {\
    if ([NSThread isMainThread]) {\
        callback(first_param, error);\
    } else {\
        dispatch_async(dispatch_get_main_queue(), ^{\
            callback(first_param, error);\
        }); \
    } \
}

#define LCIM_WAIT_TIL_TRUE(signal, interval) \
do {                                       \
    while(!(signal)) {                     \
        @autoreleasepool {                 \
            if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:(interval)]]) { \
                [NSThread sleepForTimeInterval:(interval)]; \
            }                              \
        }                                  \
    }                                      \
} while (NO)
