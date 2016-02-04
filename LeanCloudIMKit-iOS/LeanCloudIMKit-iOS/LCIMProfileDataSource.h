//
//  LCIMProfileDataSource.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import "LCIMUserModelDelegate.h"

/**
 * You can implement `-profilesWithUserIds:callback` to allow LeanCloudIMKit to get user information by user id.
 * The following example shows how to use AVUser as the user system:

 - (void)getProfilesWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMResultCallBack)callback {
    NSMutableArray<id<LCIMUserModelDelegate>> *userList = [NSMutableArray array];
    for (NSString *userId in userIds) {
        //MyUser is a subclass of AVUser, conforming to the LCIMUserModelDelegate protocol.
        AVQuery *query = [MyUser query];
        NSError *error = nil;
        MyUser *object = [query getObjectWithId:userId error:&error];
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

*/

typedef void (^LCIMResultCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);

@protocol LCIMProfileDataSource <NSObject>

@required

/*!
 * @brief Get user information by user id.
 * @attention  You could get user information by user id with either a synchronous or an asynchronous implementation.
 * @remark You must implement this method `-[LCIMProfileDataSource getProfilesWithUserIds:callback]`, so LeanCloudIMKit can get user information by user id.
 */
- (void)getProfilesWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMResultCallBack)callback;

@end