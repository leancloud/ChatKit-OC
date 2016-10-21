//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit

@import Foundation;
#import "ChatKitHeaders.h"

/*
 
 LCChatKit manages the main service of the LeanCloudChatKit-iOS, such as, open, close, set up appid and appkey, and start chatting.
 
 To use LCChatKit, steps are as follows:
 
 1. Invoke `-[AVOSCloud setAppId:appKey:]` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 2. Invoke `-[LCChatKit setAppId:appKey:]` after your login **everytime** to start ChatKit service.
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
 *
 * @brief Set up application id(appId) and client key(appKey) to start LeanCloud service.
 * @attention 请区别 `[AVOSCloud setApplicationId:appId clientKey:appKey];` 与 `[LCChatKit setAppId:appId appKey:appKey];`。
              两者功能并不相同，前者不能代替后者。即使你在 `-[AppDelegate application:didFinishLaunchingWithOptions:]` 方法里已经设置过前者，也不能因此不调用后者。
              前者为 LeanCloud-SDK 初始化，后者为 ChatKit 初始化。后者需要你在**每次**登录操作时调用一次，前者只需要你在程序启动时调用。
              如果你使用了 LeanCloud-SDK 的其他功能，你可能要根据需要，这两个方法都使用到。
 */
+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey;

/*!
 *  Returns the shared instance of LCChatKit, creating it if necessary.
 *
 *  @return Shared instance of LCChatKit.
 */
+ (instancetype)sharedInstance;

@end
