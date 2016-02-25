//
//  LCIMUserSystemService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMUserSystemService.h"

@interface LCIMUserSystemService ()

@property (nonatomic, copy, readwrite) LCIMFetchProfilesBlock fetchProfilesBlock;

@end

@implementation LCIMUserSystemService

- (NSArray<id<LCIMUserModelDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCIMUserModelDelegate>> *blockUsers = [NSArray array];
    __block BOOL hasCallback = NO;
    __block NSError *blockError;
    [self getProfilesInBackgroundForUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
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

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_fetchProfilesBlock) {
            // This enforces implementing `-setFetchProfilesBlock:`.
            NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id."];
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:reason
                                         userInfo:nil];
            return;
        }
        _fetchProfilesBlock(userIds, callback);
    });
}

@end