//
//  LCIMChatManager.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMProfileDataSource.h"
#import "LCIMSignatureDataSource.h"

/*
 LCIMChatManager manage the main service of the LeanCloudIMKit-iOS, such as, open, close and set up appid and appkey.

 To use LCIMChatManager, steps are as follows:
 
 1. Invoke `-setAppId:appKey:` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 2. Invoke `-sharedInstance` to get a singleton instance.
 3. Invoke `-openWithClientId:callback` to log in LeanCloud IM service and begin chatting.
 4. Invoke `-closeWithCallback` to log out LeanCloud IM service and end chatting.
 5. Bound a delegate object to the property named `profileDataSource`, let the delegate object implement the method `-[LCIMProfileDataSource getProfilesWithUserIds:callback]`. The delegate is
 invoked for getting the user information by the user id. 
 6. Invoke `-getProfilesInBackgroundWithUserIds:callback` or `-getProfilesWithUserIds:error` to get users' information by users' ids.
 7. Bound a delegate object to the property named `signatureDataSource`, let the delegate object implement the method `-[LCIMSignatureDataSource signatureWithClientId:conversationId:action:actionOnClientIds:]`. The delegate is
 invoked for pinning signature to these actions: open, start(create conversation), kick, invite.
 
 */

typedef void (^LCIMBoolCallBack)(NSArray *users, NSError *error);

@interface LCIMChatManager : NSObject

/*!
 * @brief Implement the method `-[LCIMProfileDataSource getProfilesWithUserIds:callback]`, so LeanCloudIMKit can get the user information by the user id.
 */
@property (nonatomic, weak) id<LCIMProfileDataSource> profileDataSource;

/*!
 * @brief if you need to pin the signature to your open client action, you should implement the method of signatureDataSource.
 * @attention if not implemented, LeanCloudIMKit will not pin the signature to these actions: open, start(create conversation), kick, invite.
 */
@property (nonatomic, weak) id<LCIMSignatureDataSource> signatureDataSource;

/*!
 * @brief set up application id(appId) and client key(appKey) to start LeanCloud service.
 * @attention must be called before `+[LCIMChatManager sharedInstance]`
 */
+ (instancetype)setAppId:(NSString *)appId appKey:(NSString *)appKey;

/*!
 * @brief create a singleton instance of LCIMChatManager
 * @attention sharedInstance must be called after `+[LCIMChatManager setAppId:appKey]`
 */
+ (instancetype)sharedInstance;

/*!
 * @param clientId The user id in your user system, LeanCloudIMKit will get the current user's information by both this id and the method `-[LCIMProfileDataSource getProfilesWithUserIds:callback:]`.
 * @param callback callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCIMBoolCallBack)callback;

/*!
 * @brief close the client
 * @param callback callback
 */
- (void)closeWithCallback:(LCIMBoolCallBack)callback;

/*!
 * @brief get user information by ids with an asynchronous implementation.
 * @attention Using this method means that the action to get every user's information is asynchronous.
 * @remark You must implement this method `[LCIMProfileDataSource getProfilesInBackgroundWithUserIds:callback]`, so LeanCloudIMKit can get the user information by the user id.
 */
- (void)getProfilesInBackgroundWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMResultCallBack)callback;

/*!
 * @brief get users' information by ids with a synchronous implementation.
 * @attention Using this method means that the action to get every user's information is synchronous.
 * @remark You must implement this method `[LCIMProfileDataSource getProfilesInBackgroundWithUserIds:callback]`, so LeanCloudIMKit can get the user information by the user id.
 * @return users' information.
 */
- (NSArray<id<LCIMUserModelDelegate>> *)getProfilesWithUserIds:(NSArray<NSString *> *)userIds error:(NSError * __autoreleasing *)error;

@end
