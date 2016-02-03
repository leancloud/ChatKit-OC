
//
//  LCIMChatManager.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMChatManager.h"
#import <AVOSCloud/AVOSCloud.h>

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
} while (0)

static LCIMChatManager *_sharedLCIMChatManager = nil;

@implementation LCIMChatManager

+ (instancetype)setAppId:(NSString *)appId appKey:(NSString *)appKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVOSCloud setApplicationId:appId clientKey:appKey];
        _sharedLCIMChatManager = [[self alloc] init];
    });
    return _sharedLCIMChatManager;
}

/**
 * create a singleton instance of LCIMChatManager
 */
+ (instancetype)sharedInstance {
    if (!_sharedLCIMChatManager) {
        NSString *reason = @"sharedInstance called before `+[LCIMChatManager setAppId:appKey:]`";
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
    return _sharedLCIMChatManager;
}

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBoolCallBack)callback {
    //TODO:
}

- (void)closeWithCallback:(LCIMBoolCallBack)callback {
    //TODO:
}

- (NSArray<id<LCIMUserModelDelegate>> *)getProfilesWithUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCIMUserModelDelegate>> *blockUsers = [NSArray array];
    __block BOOL hasCallback = NO;
    __block NSError *blockError;
    [self getProfilesInBackgroundWithUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
        if (error) {
            blockError = error;
        }
        hasCallback = YES;
        blockUsers = users;
    }];
    LCIM_WAIT_TIL_TRUE(hasCallback, 0.1);
    if (theError != NULL) {
        *theError = blockError;
    }
    return blockUsers;
}

- (void)getProfilesInBackgroundWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMResultCallBack)callback {
    if (![self.profileDataSource respondsToSelector:@selector(getProfilesWithUserIds:callback:)]) {
        NSString *reason = [NSString stringWithFormat:@"You must implement this method `-[LCIMProfileDataSource getProfilesWithUserIds:callback]`, so LeanCloudIMKit can get the user information by the user id."];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self.profileDataSource getProfilesWithUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
            safeBlock(users);
        }];
    });
}

@end
