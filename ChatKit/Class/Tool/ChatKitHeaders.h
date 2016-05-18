//
//  IMKitHeaders.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

FOUNDATION_EXPORT double LCChatKitVersionNumber;
FOUNDATION_EXPORT const unsigned char LCChatKitVersionString[];

#if __has_include(<AVOSCloud/AVOSCloud.h>)
#import <AVOSCloud/AVOSCloud.h>
#else
#import "AVOSCloud.h"
#endif

#if __has_include(<AVOSCloudIM/AVOSCloudIM.h>)
#import <AVOSCloudIM/AVOSCloudIM.h>
#else
#import "AVOSCloudIM.h"
#endif

#if __has_include(<LCChatKit/LCChatKit.h>)

#import <LCChatKit/LCCKConstants.h>
#import <LCChatKit/LCCKSessionService.h>
#import <LCChatKit/LCCKUserSystemService.h>
#import <LCChatKit/LCCKSignatureService.h>
#import <LCChatKit/LCCKSettingService.h>
#import <LCChatKit/LCCKUIService.h>
#import <LCChatKit/LCCKConversationService.h>
#import <LCChatKit/LCCKConversationListService.h>
#import <LCChatKit/LCCKServiceDefinition.h>
#import <LCChatKit/LCCKConversationViewController.h>
#import <LCChatKit/LCCKConversationListViewController.h>
#import <LCChatKit/AVIMConversation+LCCKAddition.h>

#else

#import "LCCKConstants.h"
#import "LCCKSessionService.h"
#import "LCCKUserSystemService.h"
#import "LCCKSignatureService.h"
#import "LCCKSettingService.h"
#import "LCCKUIService.h"
#import "LCCKConversationService.h"
#import "LCCKConversationListService.h"
#import "LCCKServiceDefinition.h"
#import "LCCKConversationViewController.h"
#import "LCCKConversationListViewController.h"
#import "AVIMConversation+LCCKAddition.h"

#endif



