//
//  LCIMChatService_internal.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import "LCIMUserModelDelegate.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

/**
 * 1. You must implement `-profilesWithUserIds:callback` to allow LeanCloudIMKit to get user information by user id.
 *   The following example shows how to use AVUser as the user system:

 ```
 - (void)getProfilesWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback {
    NSMutableArray<id<LCIMUserModelDelegate>> *userList = [NSMutableArray array];
    for (NSString *userId in userIds) {
        //MyUser is a subclass of AVUser, conforming to the LCIMUserModelDelegate protocol.
        AVQuery *query = [MyUser query];
        NSError *error = nil;
        MyUser *object = [query getObjectWithId:userId error:&error];
        if (error == nil) {
            [userList addObject:object];
        } else {
            if (callback) {
                callback(nil, error);
                return;
            }
        }
    }
    if (callback) {
        callback(userList, nil);
    }
 }
 ```

 * 2. Implementing `-signatureWithClientId:conversationId:action:actionOnClientIds:` means letting LeanCloudIMKit pin signature to these actions: open, start(create conversation), kick, invite.
 
*/

typedef void (^LCIMUserResultCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);

@protocol LCIMChatService <NSObject>

@required

/*!
 * @brief Get user information by user id.
 * @attention  You could get user information by user id with either a synchronous or an asynchronous implementation.
 * @remark You must implement `-getProfilesWithUserIds:callback`, so LeanCloudIMKit can get user information by user id.
 */
- (void)getProfilesWithUserIds:(NSArray<NSString *> *)userIds callback:(LCIMUserResultCallBack)callback;

@optional

/*!
 *  @brief Pin signature to these actions: open, start(create conversation), kick, invite.
 *  @param clientId - Id of operation initiator
 *  @param conversationId －  Id of target conversation
 *  @param action － Kinds of action:
                     "open": log in an account
                     "start": create a conversation
                     "add": invite myself or others to the conversation
                     "remove": kick someone out the conversation
 *  @param clientIds － Target id list for the action
 *  @return oject of AVIMSignature
 *  @attention Implementing `-signatureWithClientId:conversationId:action:actionOnClientIds:` means letting LeanCloudIMKit pin signature to these actions: open, start(create conversation), kick, invite.
 */
- (AVIMSignature *)signatureWithClientId:(NSString *)clientId
                          conversationId:(NSString *)conversationId
                                  action:(NSString *)action
                       actionOnClientIds:(NSArray *)clientIds;

@end