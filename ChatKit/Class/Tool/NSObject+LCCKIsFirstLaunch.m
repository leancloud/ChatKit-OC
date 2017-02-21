//
//  NSObject+IsFirstLaunch.m
//  ElonChan 
//
//  v0.8.5 Created by chenyilong on 15/6/15.
//  Copyright © 2015年 ElonChan . All rights reserved.
//

#import "NSObject+LCCKIsFirstLaunch.h"

@implementation NSObject (LCCKIsFirstLaunch)

- (BOOL)lcck_isFirstLaunchToEvent:(NSString *)eventName
                  evenUpdate:(BOOL)evenUpdate
                 firstLaunch:(LCCKFirstLaunchBlock)firstLaunch {
    BOOL isFirstLaunchAfterUpdateToEvent = NO;
    NSString *isAlreadyDoneEventKey;
    if (!evenUpdate) {
        isAlreadyDoneEventKey = [NSString stringWithFormat:@"isAlreadyDoneFor%@", eventName];
    } else {
        isAlreadyDoneEventKey = [NSString stringWithFormat:@"isAlreadyDoneFor%@InVersion%@", eventName, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    }
    //check if has been done
    if (![[NSUserDefaults standardUserDefaults] valueForKey:isAlreadyDoneEventKey]) {
        //外部实现了block // block 返回YES，更新targetName操作成功
        if(firstLaunch && firstLaunch()) {
            // Set the value to YES
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [[NSUserDefaults standardUserDefaults] setValue:@YES forKey:isAlreadyDoneEventKey];
            });
            isFirstLaunchAfterUpdateToEvent = YES;
        }
    }
    //仅仅在firstLaunch()返回为ture时，返回YES。换句话讲：（不仅在非第一次启动时，返回NO，而且也在firstLaunch()不返回YES时也会返回NO）
    return isFirstLaunchAfterUpdateToEvent;
}

@end
