//
//  LCIMConstants.h
//  LeanCloudIMKit-iOS
//
//  Created by EloncChan on 16/2/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Common typdef and constants, and so on.

#import "LCIMUserModelDelegate.h"

//Callback with Custom type
typedef void (^LCIMUserResultCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);
//Callback with Foundation type
typedef void (^LCIMBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^LCIMIntegerResultBlock)(NSInteger number, NSError *error);
typedef void (^LCIMStringResultBlock)(NSString *string, NSError *error);
typedef void (^LCIMDictionaryResultBlock)(NSDictionary * dict, NSError *error);
typedef void (^LCIMArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^LCIMSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^LCIMDataResultBlock)(NSData *data, NSError *error);
typedef void (^LCIMIdResultBlock)(id object, NSError *error);
//Callback with Function object
typedef void (^LCIMImageResultBlock)(UIImage * image, NSError *error);
typedef void (^LCIMProgressBlock)(NSInteger percentDone);

#define LCIM_DEPRECATED(explain) __attribute__((deprecated(explain)))

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
