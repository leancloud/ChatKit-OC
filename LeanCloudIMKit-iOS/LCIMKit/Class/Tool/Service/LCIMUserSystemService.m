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
@property (nonatomic, strong) NSMutableDictionary *cachedUserNames;
@property (nonatomic, strong) NSMutableDictionary *cachedUserAvators;

@end

@implementation LCIMUserSystemService

/**
 * create a singleton instance of LCIMUserSystemService
 */
+ (instancetype)sharedInstance {
    static LCIMUserSystemService *_sharedLCIMUserSystemService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMUserSystemService = [[self alloc] init];
    });
    return _sharedLCIMUserSystemService;
}

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
    
    
    _fetchProfilesBlock(userIds, ^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
        blockUsers = users;
        for (id<LCIMUserModelDelegate> user in users) {
            self.cachedUsers[user.userId] = user;
        }
    });
    
    

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
            if (!error) {
                for (id<LCIMUserModelDelegate> user in users) {
                    if (user.name) {
                        self.cachedUserNames[user.userId] = user.name;
                    }
                    if (user.avatorURL) {
                        self.cachedUserAvators[user.userId] = user.avatorURL;
                    }
                }
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
    [self getProfilesInBackgroundForUserIds:@[userId] callback:^(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error) {
        if (!error && (users.count > 0)) {
            !callback ?: callback(users[0], nil);
            return;
        }
        !callback ?: callback(nil, error);
    }];
}

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatorURL:(NSURL **)avatorURL error:(NSError * __autoreleasing *)theError {
    NSString *userName_ = nil;
    NSURL *avatorURL_ = nil;
    if (userId) {
        userName_ = self.cachedUserNames[userId];
        avatorURL_ = self.cachedUserAvators[userId];
    }
    if (userName_ || avatorURL_) {
        if (*name == nil) {
            *name = userName_;
        }
        if (*avatorURL == nil) {
            *avatorURL = avatorURL_;
        }
        return;
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
    [self.cachedUserAvators removeObjectForKey:peerId];
    [self.cachedUserNames removeObjectForKey:peerId];
}

- (void)removeAllCachedProfiles {
    self.cachedUserAvators = nil;
    self.cachedUserNames = nil;
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
    NSLog(@"%@", error);
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
 *  lazy load cachedUserNames
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)cachedUserNames {
    if (_cachedUserNames == nil) {
        NSMutableDictionary *cachedUserNames = [[NSMutableDictionary alloc] init];
        _cachedUserNames = cachedUserNames;
    }
    return _cachedUserNames;
}

/**
 *  lazy load cachedUsers
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)cachedUsers {
    if (_cachedUsers == nil) {
        NSMutableDictionary *cachedUsers = [[NSMutableDictionary alloc] init];
        _cachedUsers = cachedUsers;
    }
    return _cachedUsers;
}

/**
 *  lazy load cachedUserAvators
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)cachedUserAvators {
    if (_cachedUserAvators == nil) {
        NSMutableDictionary *cachedUserAvators = [[NSMutableDictionary alloc] init];
        _cachedUserAvators = cachedUserAvators;
    }
    return _cachedUserAvators;
}

@end