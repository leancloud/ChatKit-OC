//
//  LCChatKit_Internal.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//
#import "LCChatKit.h"

@class LCCKSessionService;
@class LCCKUserSystemService;
@class LCCKSignatureService;
@class LCCKSettingService;
@class LCCKUIService;
@class LCCKConversationService;
@class LCCKConversationListService;

@interface LCChatKit (LCCKServices)

/*!
 * open or close client Service
 */
@property (nonatomic, strong, readonly) LCCKSessionService *sessionService;

/*!
 * User-System Service
 */
@property (nonatomic, strong, readonly) LCCKUserSystemService *userSystemService;

/*!
 * Signature Service
 */
@property (nonatomic, strong, readonly) LCCKSignatureService *signatureService;

/*!
 * Setting Service
 */
@property (nonatomic, strong, readonly) LCCKSettingService *settingService;

/*!
 * UI Service
 */
@property (nonatomic, strong, readonly) LCCKUIService *UIService;

/*!
 * Conversation Service
 */
@property (nonatomic, strong, readonly) LCCKConversationService *conversationService;

/*!
 * Conversation List Service
 */
@property (nonatomic, strong, readonly) LCCKConversationListService *conversationListService;

@end
