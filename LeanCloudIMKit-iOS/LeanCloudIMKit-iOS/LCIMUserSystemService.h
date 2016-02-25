//
//  LCIMUserSystemService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for User-System.

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"

/**
 *  You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id.
 *   The following example shows how to use AVUser as the user system:

 ```
    [[[LCIMKit sharedInstance] userSystemService] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback) {
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

@interface LCIMUserSystemService : NSObject

@property (nonatomic, copy, readonly) LCIMFetchProfilesBlock fetchProfilesBlock;

/**
 *  @brief Add the ablitity to fetch profiles.
 *  @attention  You could get user information by user id with either a synchronous or an asynchronous implementation.
 *              If implemeted, this block will be invoked automatically by LeanCloudIMKit for fetching user profile.
 */
- (void)setFetchProfilesBlock:(LCIMFetchProfilesBlock)fetchProfilesBlock;

/*!
 * @brief Get user information by user id with a synchronous implementation.
 * @attention Using this method means that the action to get every user's information is synchronous.
 *            You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id.
 *            Otherwise, LeanCloudIMKit will throw an exception to draw your attention.
 * @return User information.
 */
- (NSArray<id<LCIMUserModelDelegate>> *)getProfilesForUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)error;

/*!
 * @brief Get user information by user id with an asynchronous implementation.
 * @attention Using this method means that the action to get every user's information is asynchronous.
 *            You must implement `-setFetchProfilesBlock:` to allow LeanCloudIMKit to get user information by user id.
 *            Otherwise, LeanCloudIMKit will throw an exception to draw your attention.
 */
- (void)getProfilesInBackgroundForUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback;

@end
