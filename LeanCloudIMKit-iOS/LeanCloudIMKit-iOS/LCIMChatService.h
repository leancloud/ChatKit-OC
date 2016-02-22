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
 
 LCIMChatService manages the main service of the LeanCloudIMKit-iOS, such as, open, close and set up appid and appkey, and gives a base class for start chatting.

 To use LCIMChatService, steps are as follows:
 1. Subclass LCIMChatService, for example name it as MyChatService.
 2. Invoke `-[MyChatService setAppId:appKey:]` in `-[AppDelegate application:didFinishLaunchingWithOptions:]` to start LeanCloud service.
 3. Invoke `-[MyChatService sharedInstance]` to get a singleton instance.
 4. Invoke `-[MyChatService openWithClientId:callback:]` to log in LeanCloud IM service and begin chatting.
 5. Invoke `-[MyChatService closeWithCallback:]` to log out LeanCloud IM service and end chatting.
 6. Implement `-[id<LCIMChatService> getProfilesInBackgroundWithUserIds:callback]` in the subclass of LCIMChatService, so LeanCloudIMKit can get user information by user id. Inculding `#import "LCIMChatService+Subclass.h"` or `#import "LeanCloudIMKit.h"` in the subclass interface file provides both asynchronous and asynchronous implementations automatically. `LCIMChatService_internal.h` file gives an example showing how to use AVUser as the user system.
 7. Implement `-[id<LCIMChatService> signatureWithClientId:conversationId:action:actionOnClientIds:]` in the subclass of LCIMChatService. If implemeted, this method will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.

 */

@interface LCIMChatService : NSObject <LCIMChatService>

/*!
 * @brief Set up application id(appId) and client key(appKey) to start LeanCloud service.
 */
+ (void)setAppId:(NSString *)appId appKey:(NSString *)appKey;

/*!
 *  Returns the shared instance of the receiver class, creating it if necessary.
 *
 *  You shoudn't override this method in your subclasses.
 
 *  @return Shared instance of the receiver class.
 */
+ (instancetype)sharedInstance;

/*!
 *  `sharedInstance` alias.
 
 *  @return Shared instance of the receiver class.
 */
+ (instancetype)instance;

/**
 *  A Boolean value that indicates whether the receiver has been initialized.
 *
 *  This property is usefull if you make you own initializer or override `-init` method.
 *  You should check if your singleton object has already been initialized to prevent repeated initialization in your custom initializer.
 
 *  @warning *Important:* you should check whether your instance already initialized before calling `[super init]`.

 ```
	- (id)init
	{
        if (!self.isInitialized) {
            self = [super init];
		
            if (self) {
                // Initialize self.
            }
        }
 
		return self;
	}
 ```
*/
@property (assign, readonly) BOOL isInitialized;

/**
 *  Destroys shared instance of singleton class (if there are no other references to that instance).
 *
 *  @warning *Note:* calling `+sharedInstance` after calling this method will create new singleton instance.
 */
+ (void)destroyInstance;

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