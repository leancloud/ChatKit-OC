//
//  LCIMChatService+Subclass.h
//  LeanCloudIMKit-iOS
//
//  Created by EloncChan on 16/2/19.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@class LCIMChatService;

@interface LCIMChatService (Subclass)

/*!
 * @brief Get user information by user id with an asynchronous implementation.
 * @attention Using this method means that the action to get every user's information is asynchronous.
 * @remark You must implement `[id<LCIMChatService> getProfilesInBackgroundWithUserIds:callback]` in the subclass LCIMChatService, so LeanCloudIMKit can get user information by user id with this method.
 */
- (void)lc_getProfilesInBackgroundWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback;

/*!
 * @brief Get user information by user id with a synchronous implementation.
 * @attention Using this method means that the action to get every user's information is synchronous.
 * @remark You must implement `[id<LCIMChatService> getProfilesInBackgroundWithUserIds:callback]` in the subclass LCIMChatService, so LeanCloudIMKit can get user information by user id with this method.
 * @return User information.
 */
- (NSArray<id<LCIMUserModelDelegate>> *)lc_getProfilesWithUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)error;

@end
