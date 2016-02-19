
//
//  LCIMChatService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMChatService.h"
#import <AVOSCloud/AVOSCloud.h>
#import "LCIMConstants.h"

static LCIMChatService *_sharedLCIMChatService = nil;

@interface LCIMChatService ()

@property (nonatomic, strong) AVIMClient *client;

@end

@implementation LCIMChatService

+ (instancetype)setAppId:(NSString *)appId appKey:(NSString *)appKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AVOSCloud setApplicationId:appId clientKey:appKey];
        _sharedLCIMChatService = [[self alloc] init];
    });
    return _sharedLCIMChatService;
}

/**
 * create a singleton instance of LCIMChatService
 */
+ (instancetype)sharedInstance {
    if (!_sharedLCIMChatService) {
        NSString *reason = @"sharedInstance called before `+[LCIMChatService setAppId:appKey:]`";
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
    return _sharedLCIMChatService;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self doesNotRecognizeSelector:_cmd];
    }
    return self;
}

- (void)openWithClientId:(NSString *)clientId callback:(LCIMBoolCallBack)callback {
    //TODO:
}

- (void)closeWithCallback:(LCIMBoolCallBack)callback {
    //TODO:
}

#pragma mark -
#pragma mark - LCIMChatService Method

- (void)getProfilesWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback {
    // This enforces implementing this method in subclasses
    NSString *reason = [NSString stringWithFormat:@"You must implement `-[id<LCIMChatService> getProfilesWithUserIds:callback]` in the subclass of LCIMChatService, so LeanCloudIMKit can get user information by user id."];
    @throw [NSException exceptionWithName:NSGenericException
                                   reason:reason
                                 userInfo:nil];
}

@end

@implementation LCIMChatService (Subclass)

- (NSArray<id<LCIMUserModelDelegate>> *)lc_getProfilesWithUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCIMUserModelDelegate>> *blockUsers = [NSArray array];
    __block BOOL hasCallback = NO;
    __block NSError *blockError;
    [self lc_getProfilesInBackgroundWithUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
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

- (void)lc_getProfilesInBackgroundWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self getProfilesWithUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
            safeBlock(users);
        }];
    });
}

@end