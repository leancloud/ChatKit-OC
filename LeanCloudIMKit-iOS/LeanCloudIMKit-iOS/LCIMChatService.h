//
//  LCIMChatService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMConstants.h"
#import "LCIMChatService_internal.h"

/*
 
 LCIMChatService manage the main service of the LeanCloudIMKit-iOS, such as, open, close and set up appid and appkey.

 To use LCIMChatService, steps are as follows:
 1. Subclass LCIMChatService.
 2. Subclass of LCIMChatService invoke `-setAppId:appKey:` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 3. Subclass of LCIMChatService invoke `-sharedInstance` to get a singleton instance.
 4. Subclass of LCIMChatService invoke `-openWithClientId:callback` to log in LeanCloud IM service and begin chatting.
 5. Subclass of LCIMChatService invoke `-closeWithCallback` to log out LeanCloud IM service and end chatting.
 6. Implement `[id<LCIMChatService> getProfilesInBackgroundWithUserIds:callback]` in the subclass of LCIMChatService, so LeanCloudIMKit can get user information by user id. Inculding `#import "LCIMChatService+Subclass.h"` or `#import "LeanCloudIMKit.h"` in the subclass interface file provides both asynchronous and asynchronous implementations automatically. `LCIMChatService_internal.h` file gives an example showing how to use AVUser as the user system.
 7. Implement `-[id<LCIMChatService> signatureWithClientId:conversationId:action:actionOnClientIds:]` in the subclass of LCIMChatService.If implemeted, this method will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.

 */

@interface LCIMChatService : NSObject <LCIMChatService>

/*!
 * @brief Set up application id(appId) and client key(appKey) to start LeanCloud service.
 * @attention This must be called before `+[LCIMChatService sharedInstance]`
 */
+ (instancetype)setAppId:(NSString *)appId appKey:(NSString *)appKey;

/*!
 * @brief Create a singleton instance of LCIMChatManager
 * @attention `sharedInstance` must be called after `+[LCIMChatManager setAppId:appKey]`
 */
+ (instancetype)sharedInstance;

/*!
 * @param clientId The user id in your user system, LeanCloudIMKit will get the current user's information by both this id and the method `-[LCIMChatService getProfilesWithUserIds:callback:]`.
 * @param callback Callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCIMBoolCallBack)callback;

/*!
 * @brief Close the client
 * @param callback Callback
 */
- (void)closeWithCallback:(LCIMBoolCallBack)callback;

@end
