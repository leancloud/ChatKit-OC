//
//  LCIMServiceDefinition.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  All the Typedefine for all kinds of services.

#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMConstants.h"

///--------------------------------------------------------------------
///----------------------LCIMUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUserSystemService

/*!
 *  @brief When fetching profiles completes, this callback will be invoked to notice LeanCloudIMKit
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason. 
 */
typedef void(^LCIMFetchProfilesCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);

/*!
 *  @brief When LeanCloudIMKit wants to fetch profiles, this block will be invoked.
 *  @param userId User Id
 *  @param callback When fetching profiles completes, this callback will be invoked on main thread to notice LeanCloudIMKit.
 */
typedef void(^LCIMFetchProfilesBlock)(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback);

///--------------------------------------------------------------------
///----------------------LCIMSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSignatureService

/*!
 *  When fetching signature information completes, this callback will be invoked to notice LeanCloudIMKit.
 *  @attention If you fetch AVIMSignature fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCIMSignatureInfoCallBack)(AVIMSignature *signature, NSError *error);

/*!
 *  @brief If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 *  @param clientId - Id of operation initiator
 *  @param conversationId －  Id of target conversation
 *  @param action － Kinds of action:
                    "open": log in an account
                    "start": create a conversation
                    "add": invite myself or others to the conversation
                    "remove": kick someone out the conversation
 *  @param clientIds － Target id list for the action
 *  @param callback - When fetching signature information complites, this callback will be invoked on main thread to notice LeanCloudIMKit.
 */
typedef void(^LCIMSignatureInfoBlock)(NSString *clientId, NSString *conversationId, NSString *action, NSArray *clientIds, LCIMSignatureInfoCallBack callback);
