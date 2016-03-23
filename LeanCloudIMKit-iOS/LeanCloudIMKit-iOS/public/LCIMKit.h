//
//  LCIMKit.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudIMKit

@import Foundation;
#import "IMKitHeaders.h"

/*
 
 LCIMKit manages the main service of the LeanCloudIMKit-iOS, such as, open, close and set up appid and appkey, and gives a base class for start chatting.
 
 To use LCIMKit, steps are as follows:
 
 1. Invoke `-[LCIMKit setAppId:appKey:]` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 2. Invoke `-[LCIMKit sharedInstance]` to get a singleton instance.
 3. Invoke `-[[LCIMKit sharedInstance] openWithClientId:callback:]` to log in LeanCloud IM service and begin chatting.
 4. Invoke `-[[LCIMKit sharedInstance] closeWithCallback:]` to log out LeanCloud IM service and end chatting.
 5. Implement `-[[LCIMKit sharedInstance] setFetchProfilesBlock:]`, so LeanCloudIMKit can get user information by user id. `LCIMUserSystemService.h` file gives an example showing how to use AVUser as the user system.
 6. Implement `-[[LCIMKit sharedInstance] setGenerateSignatureBlock:]`. If implemeted, this method will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 
 */

@interface LCIMKit : NSObject <LCIMSessionService, LCIMUserSystemService, LCIMSignatureService, LCIMSettingService, LCIMUIService, LCIMConversationService, LCIMConversationsListService>

/*!
 *  appId
 */
@property (nonatomic, copy, readonly) NSString *appId;

/*!
 *  appkey
 */
@property (nonatomic, copy, readonly) NSString *appKey;

/*!
 * @brief Set up application id(appId) and client key(appKey) to start LeanCloud service.
 */
+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey;

/*!
 *  Returns the shared instance of LCIMKit, creating it if necessary.
 *
 *  @return Shared instance of LCIMKit.
 */
+ (instancetype)sharedInstance;

@end
