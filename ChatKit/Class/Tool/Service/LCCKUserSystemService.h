//
//  LCCKUserSystemService.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for User-System.

#import <Foundation/Foundation.h>
#import "LCCKServiceDefinition.h"
#import "LCCKUserDelegate.h"

/**
 *  You must implement `-setFetchProfilesBlock:` to allow LeanCloudChatKit to get user information by user clientId.
 *   The following example shows how to use AVUser as the user system:

 ```
    [[LCChatKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCCKFetchProfilesCompletionHandler completionHandler) {
        NSMutableArray<id<LCCKUserDelegate>> *userList = [NSMutableArray array];
        for (NSString *userId in userIds) {
            //MyUser is a subclass of AVUser, conforming to the LCCKUserDelegate protocol.
            AVQuery *query = [LCCKUser query];
            NSError *error = nil;
            LCCKUser *object = (LCCKUser *)[query getObjectWithId:userId error:&error];
            if (error == nil) {
                [userList addObject:object];
            } else {
                if (completionHandler) {
                    completionHandler(nil, error);
                    return;
                }
            }
        }
        if (completionHandler) {
            completionHandler(userList, nil);
        }
    }
     ];

  ```
 
*/

/*!
 * LCCKUserSystemService error domain
 */
FOUNDATION_EXTERN NSString *const LCCKUserSystemServiceErrorDomain;

@interface LCCKUserSystemService : LCCKSingleton <LCCKUserSystemService>

- (NSArray<id<LCCKUserDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError;

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCCKUserResultsCallBack)callback;

- (id<LCCKUserDelegate>)getProfileForUserId:(NSString *)userId error:(NSError * __autoreleasing *)theError;

/*!
 * Firstly try memory cache, then fetch.
 */
- (id<LCCKUserDelegate>)fetchCurrentUser;

/*!
 * Firstly try memory cache, then fetch.
 */
- (void)fetchCurrentUserInBackground:(LCCKUserResultCallBack)callback;

- (void)cacheUsersWithIds:(NSSet<id<LCCKUserDelegate>> *)userIds callback:(LCCKBooleanResultBlock)callback;

- (void)cacheUsers:(NSArray<id<LCCKUserDelegate>> *)users;

/**
 *  清除对指定 person 的 profile 缓存
 *
 *  @param person 用户对象
 */
- (void)removeCachedProfileForPeerId:(NSString *)peerId;

- (void)removeAllCachedProfiles;

@end
