//
//  LCIMChatManager.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMProfileProviderDelegate.h"
#import "LCIMSignatureFactoryDelegate.h"

typedef void (^LCIMBoolCallBack)(NSArray *users, NSError *error);

@interface LCIMChatManager : NSObject

/*!
 * You must implement the method of LCIMProfileProviderDelegate, so we can get the user information by the user id
 */
@property (nonatomic, weak) id<LCIMProfileProviderDelegate> profileProviderDelegate;

/*!
 * if you need pin the signature to your open client action, your shoud implement the method of signatureFactoryDelegate.
 * if not implemented, we won't pin the signature to your open client action.
 */
@property (nonatomic, weak) id<LCIMSignatureFactoryDelegate> signatureFactoryDelegate;

- (instancetype)initWithAppId:(NSString *)appId appKey:(NSString *)appKey;

/*!
 * @param clientId The user id in your user systom, LeanCloudIMKit will get the current user's information by both this id and the the method `-getProfilesWithUserIds:callback:` in LCIMProfileProviderDelegate.
 * @param callback callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCIMBoolCallBack)callback;

/*!
 * @brief close the client
 * @param callback callback
 */
- (void)close:(LCIMBoolCallBack)callback;

@end
