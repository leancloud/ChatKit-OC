//
//  LCIMKit.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudIMKit

#import <Foundation/Foundation.h>
#import "LCIMLoginService.h"
#import "LCIMUserSystemService.h"
#import "LCIMSignatureService.h"

/*
 
 LCIMKit manages the main service of the LeanCloudIMKit-iOS, such as, open, close and set up appid and appkey, and gives a base class for start chatting.
 
 To use LCIMKit, steps are as follows:
 
 1. Invoke `-[LCIMKit setAppId:appKey:]` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 2. Invoke `-[LCIMKit sharedInstance]` to get a singleton instance.
 3. Invoke `-[[[LCIMKit sharedInstance] loginService] openWithClientId:callback:]` to log in LeanCloud IM service and begin chatting.
 4. Invoke `-[[[LCIMKit sharedInstance] loginService] closeWithCallback:]` to log out LeanCloud IM service and end chatting.
 5. Implement `-[[[LCIMKit sharedInstance] userSystemService] setFetchProfilesBlock:]`, so LeanCloudIMKit can get user information by user id. `LCIMUserSystemService.h` file gives an example showing how to use AVUser as the user system.
 6. Implement `-[[[LCIMKit sharedInstance] signatureService] setSignatureInfoBlock:]`. If implemeted, this method will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 
 */

@interface LCIMKit : NSObject

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

/*!
 *  `sharedInstance` alias.
 *
 *  @return Shared instance of LCIMKit.
 */
+ (instancetype)instance;

/*!
 *  Destroys shared instance of singleton class (if there are no other references to that instance).
 *
 *  @warning *Note:* calling `+sharedInstance` after calling this method will create new singleton instance.
 */
+ (void)destroyInstance;

/*!
 * Login Service
 */
@property (nonatomic, strong, readonly) LCIMLoginService *loginService;

/*!
 * User-System Service
 */
@property (nonatomic, strong, readonly) LCIMUserSystemService *userSystemService;

/*!
 * Signature Service
 */
@property (nonatomic, strong, readonly) LCIMSignatureService *signatureService;

//TODO:
/**
 *  群相关服务
 LeanCloudIMKit 的 UI 上增加以下功能:
 1. 创建群
 2. 查看群成员
 3. 增加群成员
 4. 删除群成员
 这里创建群、增加群成员的时候需要用户提供一个备选的列表，这个列表根据不同的场景有所不同，可能需要用户提供一个接口.
 */
//@property (nonatomic, strong, readonly) LCIMTribeService *tribeService;
//@property (nonatomic, strong, readonly) LCIMSettingService *settingService;

@end
