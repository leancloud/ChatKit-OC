//
//  LCIMUserSystemService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMUserSystemService.h"
#import "LCIMSessionService.h"

NSString *const LCIMUserSystemServiceErrorDomain = @"LCIMUserSystemServiceErrorDomain";

@interface LCIMUserSystemService ()

@property (nonatomic, copy, readwrite) LCIMFetchProfilesBlock fetchProfilesBlock;
@property (nonatomic, strong) NSMutableDictionary *cachedUsers;

@end

@implementation LCIMUserSystemService

- (NSArray<id<LCIMUserModelDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCIMUserModelDelegate>> *blockUsers = [NSArray array];
    //    __block BOOL hasCallback = NO;
    //    __block NSError *blockError;
    //    [self getProfilesInBackgroundForUserIds:userIds callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
    //        if (error) {
    //            blockError = error;
    //        }
    //        blockUsers = users;
    //        hasCallback = YES;
    //    }];
    //    LCIM_WAIT_TIL_TRUE(hasCallback, 0.1);
    //    if (theError != NULL) {
    //        *theError = blockError;
    //    }
    //TODO:
    if (!_fetchProfilesBlock) {
        // This enforces implementing `-setFetchProfilesBlock:`.
        NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id."];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
        return nil;
    }
    LCIMFetchProfilesCallBack callback = ^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
        blockUsers = users;
        [self cacheUsers:users];
    };
    _fetchProfilesBlock(userIds, callback);
    
    return blockUsers;
}

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultsCallBack)callback {
    if (userIds.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_fetchProfilesBlock) {
            // This enforces implementing `-setFetchProfilesBlock:`.
            NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id."];
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:reason
                                         userInfo:nil];
            return;
        }
        
        _fetchProfilesBlock(userIds, ^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
            if (!error && (users.count > 0)) {
                [self cacheUsers:users];
                dispatch_async(dispatch_get_main_queue(),^{
                    !callback ?: callback(users, nil);
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(),^{
                !callback ?: callback(nil, error);
            });
        });
    });
}

- (id<LCIMUserModelDelegate>)getProfileForUserId:(NSString *)userId error:(NSError * __autoreleasing *)theError {
    if (!userId) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserId is nil";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCIMUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        if (*theError == nil) {
            *theError = error;
        }
        return nil;
    }
    
    id<LCIMUserModelDelegate> user = [self getCachedProfileIfExists:userId error:nil];
    if (user) {
        return user;
    }
    NSArray *users = [self getProfilesForUserIds:@[userId] error:theError];
    if (users.count > 0) {
        return users[0];
    }
    return nil;
}

- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCIMUserResultCallBack)callback {
    if (!userId) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserId is nil";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCIMUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        !callback ?: callback(nil, error);
        return;
    }
    [self getProfilesInBackgroundForUserIds:@[userId] callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
        if (!error && (users.count > 0)) {
            !callback ?: callback(users[0], nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatorURL:(NSURL **)avatorURL error:(NSError * __autoreleasing *)theError {
    if (userId) {
        NSString *userName_ = nil;
        NSURL *avatorURL_ = nil;
        id<LCIMUserModelDelegate> user = self.cachedUsers[userId];
        userName_ = user.name;
        avatorURL_ = user.avatorURL;
        if (userName_ || avatorURL_) {
            if (*name == nil) {
                *name = userName_;
            }
            if (*avatorURL == nil) {
                *avatorURL = avatorURL_;
            }
            return;
        }
        
    }
    NSInteger code = 0;
    NSString *errorReasonText = @"No cached profile";
    NSDictionary *errorInfo = @{
                                @"code":@(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:LCIMUserSystemServiceErrorDomain
                                         code:code
                                     userInfo:errorInfo];
    if (*theError == nil) {
        *theError = error;
    }
}

- (void)removeCachedProfileForPeerId:(NSString *)peerId {
    [self.cachedUsers removeObjectForKey:peerId];
}

- (void)removeAllCachedProfiles {
    self.cachedUsers = nil;
}

- (id<LCIMUserModelDelegate>)fetchCurrentUser {
    NSError *error = nil;
    id<LCIMUserModelDelegate> user = [[LCIMUserSystemService sharedInstance] getCachedProfileIfExists:[LCIMSessionService sharedInstance].clientId error:&error];
    if (!error) {
        return user;
    }
    error = nil;
    id<LCIMUserModelDelegate> currentUser = [[LCIMUserSystemService sharedInstance] getProfileForUserId:[LCIMSessionService sharedInstance].clientId error:&error];
    if (!error) {
        return currentUser;
    }
//    NSLog(@"%@", error);
    return nil;
}

- (void)fetchCurrentUserInBackground:(LCIMUserResultCallBack)callback {
    NSError *error = nil;
    id<LCIMUserModelDelegate> user = [[LCIMUserSystemService sharedInstance] getCachedProfileIfExists:[LCIMSessionService sharedInstance].clientId error:&error];
    if (!error) {
        !callback ?: callback(user, nil);
        return;
    }
    
    [[LCIMUserSystemService sharedInstance] getProfileInBackgroundForUserId:[LCIMSessionService sharedInstance].clientId callback:^(id<LCIMUserModelDelegate> user, NSError *error) {
        if (!error) {
            !callback ?: callback(user, nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}


- (id<LCIMUserModelDelegate>)getCachedProfileIfExists:(NSString *)userId error:(NSError * __autoreleasing *)theError {
    id<LCIMUserModelDelegate> user;
    if (userId) {
        user = self.cachedUsers[userId];
    }
    if (user) {
        return user;
    }
    NSInteger code = 0;
    NSString *errorReasonText = @"No cached profile";
    NSDictionary *errorInfo = @{
                                @"code":@(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:LCIMUserSystemServiceErrorDomain
                                         code:code
                                     userInfo:errorInfo];
    if (theError) {
        *theError = error;
    }
    return nil;
}

- (void)cacheUsersWithIds:(NSSet<id<LCIMUserModelDelegate>> *)userIds callback:(LCIMBooleanResultBlock)callback {
    NSMutableSet *uncachedUserIds = [[NSMutableSet alloc] init];
    for (NSString *userId in userIds) {
        if ([self getCachedProfileIfExists:userId error:nil] == nil) {
            [uncachedUserIds addObject:userId];
        }
    }
    if ([uncachedUserIds count] > 0) {
        [self getProfilesInBackgroundForUserIds:[[NSMutableArray alloc] initWithArray:[uncachedUserIds allObjects]] callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
            if (users) {
                [self cacheUsers:users];
            }
            callback(YES, error);
        }];
    } else {
        callback(YES, nil);
    }
}

- (void)cacheUsers:(NSArray<id<LCIMUserModelDelegate>> *)users {
    for (id<LCIMUserModelDelegate> user in users) {
        self.cachedUsers[user.userId] = user;
    }
}

#pragma mark -
#pragma mark - LazyLoad Method

/**
 *  lazy load cachedUsers
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)cachedUsers {
    if (_cachedUsers == nil) {
        _cachedUsers = [[NSMutableDictionary alloc] init];
    }
    return _cachedUsers;
}



@end