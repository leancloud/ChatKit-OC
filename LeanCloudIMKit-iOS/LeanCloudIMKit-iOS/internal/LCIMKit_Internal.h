//
//  LCIMKit_Internal.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 EloncChan. All rights reserved.
//
#import "LCIMKit.h"

@class LCIMSessionService;
@class LCIMUserSystemService;
@class LCIMSignatureService;
@class LCIMSettingService;
@class LCIMUIService;
@class LCIMConversationService;
@class LCIMConversationListService;

@interface LCIMKit (LCIMServices)

/*!
 * open or close client Service
 */
@property (nonatomic, strong, readonly) LCIMSessionService *sessionService;

/*!
 * User-System Service
 */
@property (nonatomic, strong, readonly) LCIMUserSystemService *userSystemService;

/*!
 * Signature Service
 */
@property (nonatomic, strong, readonly) LCIMSignatureService *signatureService;

/*!
 * Setting Service
 */
@property (nonatomic, strong, readonly) LCIMSettingService *settingService;

/*!
 * UI Service
 */
@property (nonatomic, strong, readonly) LCIMUIService *UIService;

/*!
 * Conversation Service
 */
@property (nonatomic, strong, readonly) LCIMConversationService *conversationService;

/*!
 * Conversation List Service
 */
@property (nonatomic, strong, readonly) LCIMConversationListService *conversationListService;

@end