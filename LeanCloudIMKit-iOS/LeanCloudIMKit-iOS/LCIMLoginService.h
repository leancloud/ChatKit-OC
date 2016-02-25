//
//  LCIMLoginService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for loging in and loging out LeanCloud server.

#import <Foundation/Foundation.h>
#import "LCIMConstants.h"

@interface LCIMLoginService : NSObject

/*!
 * @param clientId The user id in your user system, LeanCloudIMKit will get the current user's information by both this id and the method `-[LCIMChatService getProfilesForUserIds:callback:]`.
 * @param callback Callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback;

/*!
 * @brief Close the client
 * @param callback Callback
 */
- (void)closeWithCallback:(LCIMBooleanResultBlock)callback;

@end
