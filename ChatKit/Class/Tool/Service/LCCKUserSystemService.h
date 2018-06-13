//
//  LCCKUserSystemService.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
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
            AVUser *user = [query getObjectWithId:userId error:&error];
            LCCKUser *object = [LCCKUser userWithClientId:user.objectId];
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

/*!
 * syc fetch, only fetch from network.
 */
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

@end
