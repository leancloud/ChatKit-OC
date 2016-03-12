//
//  LCIMUserSystemService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for User-System.

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"
#import "LCIMUserModelDelegate.h"

/**
 *  You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id.
 *   The following example shows how to use AVUser as the user system:

 ```
    [[LCIMKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback) {
        NSMutableArray<id<LCIMUserModelDelegate>> *userList = [NSMutableArray array];
        for (NSString *userId in userIds) {
            //MyUser is a subclass of AVUser, conforming to the LCIMUserModelDelegate protocol.
            AVQuery *query = [LCIMUser query];
            NSError *error = nil;
            LCIMUser *object = (LCIMUser *)[query getObjectWithId:userId error:&error];
            if (error == nil) {
                [userList addObject:object];
            } else {
                if (callback) {
                    callback(nil, error);
                    return;
                }
            }
        }
        if (callback) {
            callback(userList, nil);
        }
    }
     ];

  ```
 
*/

/*!
 * LCIMUserSystemService error domain
 */
FOUNDATION_EXTERN NSString *const LCIMUserSystemServiceErrorDomain;

@interface LCIMUserSystemService : NSObject <LCIMUserSystemService>

+ (instancetype)sharedInstance;

- (NSArray<id<LCIMUserModelDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)theError;

- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultsCallBack)callback;

- (id<LCIMUserModelDelegate>)getProfileForUserId:(NSString *)userId error:(NSError * __autoreleasing *)theError;

- (void)getProfileInBackgroundForUserId:(NSString *)userId callback:(LCIMUserResultCallBack)callback;

- (id<LCIMUserModelDelegate>)fetchCurrentUser;
- (void)fetchCurrentUserInBackground:(LCIMUserResultCallBack)callback;

- (void)getCachedProfileIfExists:(NSString *)userId name:(NSString **)name avatorURL:(NSURL **)avatorURL error:(NSError * __autoreleasing *)theError;

- (id<LCIMUserModelDelegate>)getCachedProfileIfExists:(NSString *)userId error:(NSError * __autoreleasing *)theError;

/**
 *  清除对指定 person 的 profile 缓存
 *
 *  @param person 用户对象
 */
- (void)removeCachedProfileForPeerId:(NSString *)peerId;

- (void)cacheUsersWithIds:(NSSet<id<LCIMUserModelDelegate>> *)userIds callback:(LCIMBooleanResultBlock)callback;

- (void)cacheUsers:(NSArray<id<LCIMUserModelDelegate>> *)users;

@end
