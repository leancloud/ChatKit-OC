//
//  LCCKUserSystemService.m
//  ChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"

NSString *const LCCKUserSystemServiceErrorDomain = @"LCCKUserSystemServiceErrorDomain";

@interface LCCKUserSystemService ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<LCCKUserDelegate>> *cachedUsers;

@property (nonatomic, strong) dispatch_queue_t isolationQueue;

@end

@implementation LCCKUserSystemService
@synthesize fetchProfilesBlock = _fetchProfilesBlock;

- (void)setFetchProfilesBlock:(LCCKFetchProfilesBlock)fetchProfilesBlock {
    _fetchProfilesBlock = fetchProfilesBlock;
}

- (NSArray<id<LCCKUserDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    __block NSArray<id<LCCKUserDelegate>> *blockUsers = [NSArray array];
    if (!_fetchProfilesBlock) {
        // This enforces implementing `-setFetchProfilesBlock:`.
        NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow ChatKit to get user information by user clientId."];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
        return nil;
    }
    LCCKFetchProfilesCompletionHandler completionHandler = ^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
        blockUsers = users;
        [self cacheUsers:users];
    };
    _fetchProfilesBlock(userIds, completionHandler);
    return blockUsers;
}

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCCKUserResultsCallBack)callback {
    if (!userIds || userIds.count == 0) {
        dispatch_async(dispatch_get_main_queue(),^{
            NSInteger code = 0;
            NSString *errorReasonText = @"members is 0";
            NSDictionary *errorInfo = @{
                                        @"code":@(code),
                                        NSLocalizedDescriptionKey : errorReasonText,
                                        };
            NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                                 code:code
                                             userInfo:errorInfo];
            !callback ?: callback(nil, error);
        });
        return;
    }
    NSError *error = nil;
    NSArray *cachedProfiles = [self getCachedProfilesIfExists:userIds error:&error];
    if (cachedProfiles.count == userIds.count) {
        dispatch_async(dispatch_get_main_queue(),^{
            !callback ?: callback(cachedProfiles, nil);
        });
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        if (!_fetchProfilesBlock) {
            // This enforces implementing `-setFetchProfilesBlock:`.
            NSString *reason = [NSString stringWithFormat:@"You must implement `-setFetchProfilesBlock:` to allow ChatKit to get user information by user clientId."];
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:reason
                                         userInfo:nil];
            return;
        }
        _fetchProfilesBlock(userIds, ^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            if (!error && users && (users.count > 0)) {
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

- (id<LCCKUserDelegate>)getProfileForUserId:(NSString *)userId error:(NSError * __autoreleasing *)theError {
    if (!userId) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserId is nil";
        NSDictionary *errorInfo = @{
                                    @"code" : @(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        
        if (theError == nil) {
            *theError = error;
        }
        return nil;
    }
    
    id<LCCKUserDelegate> user = [self getCachedProfileIfExists:userId error:nil];
    if (user) {
        return user;
    }
    NSArray *users = [self getProfilesForUserIds:@[userId] error:theError];
    if (users.count > 0) {
        return users[0];
    }
    return nil;
}

- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCCKUserResultCallBack)callback {
    if (!userId) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserId is nil";
        NSDictionary *errorInfo = @{
                                    @"code" : @(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        !callback ?: callback(nil, error);
        return;
    }
    [self getProfilesInBackgroundForUserIds:@[userId] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
        if (!error && users && (users.count > 0)) {
            !callback ?: callback(users[0], nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}

- (NSArray<id<LCCKUserDelegate>> *)getCachedProfilesIfExists:(NSArray<NSString *> *)userIds shouldSameCount:(BOOL)shouldSameCount error:(NSError * __autoreleasing *)theError {
    NSArray *cachedProfiles = [self getCachedProfilesIfExists:userIds error:theError];
    if (!shouldSameCount) {
        return cachedProfiles;
    }
    if (cachedProfiles.count == userIds.count) {
        return cachedProfiles;
    }
    return nil;
}

- (NSArray<id<LCCKUserDelegate>> *)getCachedProfilesIfExists:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError {
    if (!userIds || userIds.count == 0) {
        NSInteger code = 0;
        NSString *errorReasonText = @"UserIds is nil";
        NSDictionary *errorInfo = @{
                                    @"code" : @(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        if (theError) {
            *theError = error;
        }
        return nil;
    }
    NSMutableArray *cachedProfiles = [NSMutableArray arrayWithCapacity:self.cachedUsers.count * 0.5];
    NSArray *allCachedUserIds = [self.cachedUsers allKeys];
    [userIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allCachedUserIds containsObject:obj]) {
            [cachedProfiles addObject:[self getUserForClientId:obj]];
        }
    }];
    return [cachedProfiles copy];
}

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatarURL:(NSURL **)avatarURL error:(NSError * __autoreleasing *)theError {
    if (userId) {
        NSString *userName_ = nil;
        NSURL *avatarURL_ = nil;
        id<LCCKUserDelegate> user = [self getUserForClientId:userId];
        userName_ = user.name;
        avatarURL_ = user.avatarURL;
        if (userName_ || avatarURL_) {
            if (*name == nil) {
                *name = userName_;
            }
            if (*avatarURL == nil) {
                *avatarURL = avatarURL_;
            }
            return;
        }
        
    }
    NSInteger code = 0;
    NSString *errorReasonText = @"No cached profile";
    NSDictionary *errorInfo = @{
                                @"code" : @(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                         code:code
                                     userInfo:errorInfo];
    if (theError) {
        *theError = error;
    }
}

- (void)removeCachedProfileForPeerId:(NSString *)peerId {
    NSString *clientId_ = [peerId copy];
    if (!clientId_) {
        return;
    }
    dispatch_async(self.isolationQueue, ^(){
        [self.cachedUsers removeObjectForKey:peerId];
    });
}

- (void)removeAllCachedProfiles {
    dispatch_async(self.isolationQueue, ^(){
        self.cachedUsers = nil;
    });
}

- (id<LCCKUserDelegate>)fetchCurrentUser {
    NSError *error = nil;
    id<LCCKUserDelegate> user = [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:[LCCKSessionService sharedInstance].clientId error:&error];
    if (!error) {
        return user;
    }
    error = nil;
    id<LCCKUserDelegate> currentUser = [[LCCKUserSystemService sharedInstance] getProfileForUserId:[LCCKSessionService sharedInstance].clientId error:&error];
    if (!error) {
        return currentUser;
    }
    //    NSLog(@"%@", error);
    return nil;
}

- (void)fetchCurrentUserInBackground:(LCCKUserResultCallBack)callback {
    NSError *error = nil;
    id<LCCKUserDelegate> user = [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:[LCCKSessionService sharedInstance].clientId error:&error];
    if (!error) {
        !callback ?: callback(user, nil);
        return;
    }
    
    [[LCCKUserSystemService sharedInstance] getProfileInBackgroundForUserId:[LCCKSessionService sharedInstance].clientId callback:^(id<LCCKUserDelegate> user, NSError *error) {
        if (!error) {
            !callback ?: callback(user, nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}

- (id<LCCKUserDelegate>)getCachedProfileIfExists:(NSString *)userId error:(NSError * __autoreleasing *)theError {
    id<LCCKUserDelegate> user;
    if (userId) {
        user = [self getUserForClientId:userId];
    }
    if (user) {
        return user;
    }
    NSInteger code = 0;
    NSString *errorReasonText = @"No cached profile";
    NSDictionary *errorInfo = @{
                                @"code" : @(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:LCCKUserSystemServiceErrorDomain
                                         code:code
                                     userInfo:errorInfo];
    if (theError) {
        *theError = error;
    }
    return nil;
}

- (void)cacheUsersWithIds:(NSSet<id<LCCKUserDelegate>> *)userIds callback:(LCCKBooleanResultBlock)callback {
    NSMutableSet *uncachedUserIds = [[NSMutableSet alloc] init];
    for (NSString *userId in userIds) {
        if ([self getCachedProfileIfExists:userId error:nil] == nil) {
            [uncachedUserIds addObject:userId];
        }
    }
    if ([uncachedUserIds count] > 0) {
        [self getProfilesInBackgroundForUserIds:[[NSMutableArray alloc] initWithArray:[uncachedUserIds allObjects]] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            if (users) {
                [self cacheUsers:users];
            }
            !callback ?: callback(YES, error);
        }];
    } else {
        !callback ?: callback(YES, nil);
    }
}

//TODO:改为异步操作，启用本地缓存。只在关键操作时更新本地缓存，比如：签名机制对应的几个操作：加人、踢人等。
- (void)cacheUsers:(NSArray<id<LCCKUserDelegate>> *)users {
    if (users.count > 0) {
        for (id<LCCKUserDelegate> user in users) {
            [self setUser:user forClientId:user.clientId];
        }
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

- (dispatch_queue_t)isolationQueue {
    if (_isolationQueue) {
        return _isolationQueue;
    }
    NSString *queueBaseLabel = [NSString stringWithFormat:@"com.ChatKit.%@", NSStringFromClass([self class])];
    const char *queueName = [[NSString stringWithFormat:@"%@.ForIsolation",queueBaseLabel] UTF8String];
    _isolationQueue = dispatch_queue_create(queueName, NULL);
    return _isolationQueue;
}

#pragma mark -
#pragma mark - set or get cached user Method

- (void)setUser:(id<LCCKUserDelegate>)user forClientId:(NSString *)clientId {
    NSString *clientId_ = [clientId copy];
    if (!clientId_) {
        return;
    }
    dispatch_async(self.isolationQueue, ^(){
        if (!user) {
            [self.cachedUsers removeObjectForKey:clientId_];
        } else {
            [self.cachedUsers setObject:user forKey:clientId_];
        }
    });
}

- (id<LCCKUserDelegate>)getUserForClientId:(NSString *)clientId {
    if (!clientId) {
        return nil;
    }
    __block id<LCCKUserDelegate> user = nil;
    dispatch_sync(self.isolationQueue, ^(){
        user = self.cachedUsers[clientId];
    });
    return user;
}

@end
