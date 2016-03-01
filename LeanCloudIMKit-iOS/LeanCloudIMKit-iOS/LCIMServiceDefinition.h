//
//  LCIMServiceDefinition.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  All the Typedefine for all kinds of services.

#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMConstants.h"
@class LCIMConversationViewController;
@class LCIMConversationListViewController;

///---------------------------------------------------------------------
///---------------------LCIMSessionService------------------------------
///---------------------------------------------------------------------

@protocol LCIMSessionService <NSObject>

@property (nonatomic, copy, readonly) NSString *clientId;

/*!
 * @param clientId The peer id in your peer system, LeanCloudIMKit will get the current user's information by both this id and the method `-[LCIMChatService getProfilesForUserIds:callback:]`.
 * @param callback Callback
 */
- (void)openWithClientId:(NSString *)clientId callback:(LCIMBooleanResultBlock)callback;

/*!
 * @brief Close the client
 * @param callback Callback
 */
- (void)closeWithCallback:(LCIMBooleanResultBlock)callback;

@end

///--------------------------------------------------------------------
///----------------------LCIMUserSystemService-------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUserSystemService

@protocol LCIMUserSystemService <NSObject>

/*!
 *  @brief When fetching profiles completes, this callback will be invoked to notice LeanCloudIMKit
 *  @attention If you fetch users fails, you should reture nil, meanwhile, give the error reason. 
 */
typedef void(^LCIMFetchProfilesCallBack)(NSArray<id<LCIMUserModelDelegate>> *users, NSError *error);

/*!
 *  @brief When LeanCloudIMKit wants to fetch profiles, this block will be invoked.
 *  @param userId peer Id
 *  @param callback When fetching profiles completes, this callback will be invoked on main thread to notice LeanCloudIMKit.
 */
typedef void(^LCIMFetchProfilesBlock)(NSArray<NSString *> *userIds, LCIMFetchProfilesCallBack callback);

@property (nonatomic, copy, readonly) LCIMFetchProfilesBlock fetchProfilesBlock;

/**
 *  @brief Add the ablitity to fetch profiles.
 *  @attention  You could get peer information by peer id with either a synchronous or an asynchronous implementation.
 *              If implemeted, this block will be invoked automatically by LeanCloudIMKit for fetching peer profile.
 */
- (void)setFetchProfilesBlock:(LCIMFetchProfilesBlock)fetchProfilesBlock;

@end

///--------------------------------------------------------------------
///----------------------LCIMSignatureService--------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSignatureService

@protocol LCIMSignatureService <NSObject>

/*!
 *  When fetching signature information completes, this callback will be invoked to notice LeanCloudIMKit.
 *  @attention If you fetch AVIMSignature fails, you should reture nil, meanwhile, give the error reason.
 */
typedef void(^LCIMGenerateSignatureCallBack)(AVIMSignature *signature, NSError *error);

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
typedef void(^LCIMGenerateSignatureBlock)(NSString *clientId, NSString *conversationId, NSString *action, NSArray *clientIds, LCIMGenerateSignatureCallBack callback);

@property (nonatomic, copy, readonly) LCIMGenerateSignatureBlock generateSignatureBlock;

/*!
 * @brief Add the ablitity to pin signature to these actions: open, start(create conversation), kick, invite.
 * @attention  If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 */
- (void)setGenerateSignatureBlock:(LCIMGenerateSignatureBlock)generateSignatureBlock;

@end

///--------------------------------------------------------------------
///----------------------------LCIMUIService---------------------------
///--------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMUIService

#import "LCIMServiceDefinition.h"

@protocol LCIMUIService <NSObject>

#pragma mark - - Open Profile

/**
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
typedef void(^LCIMOpenProfileBlock)(NSString *userId, UIViewController *parentController);

@property (nonatomic, copy, readonly) LCIMOpenProfileBlock openProfileBlock;

/*!
 *  打开某个profile的回调block
 *  @param userId 某个userId
 *  @param parentController 用于打开的顶层控制器
 */
- (void)setOpenProfileBlock:(LCIMOpenProfileBlock)openProfileBlock;

@end

///---------------------------------------------------------------------
///------------------LCIMSettingService---------------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMSettingService

@protocol LCIMSettingService <NSObject>

+ (void)setAllLogsEnabled:(BOOL)enabled;
+ (BOOL)allLogsEnabled;
+ (NSString *)IMKitVersion;

@end

///---------------------------------------------------------------------
///---------------------LCIMConversationService-------------------------
///---------------------------------------------------------------------

#pragma mark -
#pragma mark - LCIMConversationService

@protocol LCIMConversationService <NSObject>

/*!
 *  根据 conversationId 获取对话
 *  @param conversationId   对话的 id
 *  @param callback
 */
- (void)fecthConversationWithConversationId:(NSString *)conversationId callback:(AVIMConversationResultBlock)callback;

/*!
 *  根据 peerId 获取对话
 *  @param peerId   对方的 id
 *  @param callback
 */
- (void)fecthConversationWithPeerId:(NSString *)peerId callback:(AVIMConversationResultBlock)callback;
    
@end

//TODO:CacheService;