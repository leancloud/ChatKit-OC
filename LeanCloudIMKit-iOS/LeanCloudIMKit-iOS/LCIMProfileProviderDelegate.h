//
//  LCIMProfileProviderDelegate.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

typedef void (^LCIMResultCallBack)(NSArray *users, NSError *error);

@protocol LCIMProfileProviderDelegate <NSObject>

@required

/*!
 * @brief get user informations by ids
 * @attention  LeanCloudIMKit will get the current user's information by both this method and the client id which is the param of `-openWithClientId:callback:` in LCIMChatManager.
 @remark You must implement the method of LCIMProfileProviderDelegate, so we can get the user information by the user id.
 */
- (void)getProfilesWithUserIds:(NSArray *)userIds callback:(LCIMResultCallBack)callback;

@end