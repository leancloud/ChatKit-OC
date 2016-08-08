//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit

@import Foundation;
#import "ChatKitHeaders.h"

/*
 
 LCChatKit manages the main service of the LeanCloudChatKit-iOS, such as, open, close and set up appid and appkey, and gives a base class for start chatting.
 
 To use LCChatKit, steps are as follows:
 
 1. Invoke `-[LCChatKit setAppId:appKey:]` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 2. Invoke `-[LCChatKit sharedInstance]` to get a singleton instance.
 3. Invoke `-[[LCChatKit sharedInstance] openWithClientId:callback:]` to log in LeanCloud IM service and begin chatting.
 4. Invoke `-[[LCChatKit sharedInstance] closeWithCallback:]` to log out LeanCloud IM service and end chatting.
 5. Implement `-[[LCChatKit sharedInstance] setFetchProfilesBlock:]`, so ChatKit can get user information by user id. `LCCKUserSystemService.h` file gives an example showing how to use AVUser as the user system.
 6. Implement `-[[LCChatKit sharedInstance] setGenerateSignatureBlock:]`. If implemeted, this method will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 
 */

@interface LCChatKit : NSObject <LCCKSessionService, LCCKUserSystemService, LCCKSignatureService, LCCKSettingService, LCCKUIService, LCCKConversationService, LCCKConversationsListService>

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
 *  Returns the shared instance of LCChatKit, creating it if necessary.
 *
 *  @return Shared instance of LCChatKit.
 */
+ (instancetype)sharedInstance;

@end
