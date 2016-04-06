//
//  IMKitHeaders.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

FOUNDATION_EXPORT double LCIMKitVersionNumber;
FOUNDATION_EXPORT const unsigned char LCIMKitVersionString[];

#if __has_include(<LCIMKit/LCIMKit.h>)

#import <LCIMKit/LCIMConstants.h>
#import <LCIMKit/LCIMSessionService.h>
#import <LCIMKit/LCIMUserSystemService.h>
#import <LCIMKit/LCIMSignatureService.h>
#import <LCIMKit/LCIMSettingService.h>
#import <LCIMKit/LCIMUIService.h>
#import <LCIMKit/LCIMConversationService.h>
#import <LCIMKit/LCIMConversationListService.h>
#import <LCIMKit/LCIMServiceDefinition.h>
#import <LCIMKit/LCIMConversationViewController.h>
#import <LCIMKit/LCIMConversationListViewController.h>
#import <LCIMKit/AVIMConversation+LCIMAddition.h>

#else

#import "AVOSCloud.h"
#import "AVOSCloudIM.h"
#import "LCIMConstants.h"
#import "LCIMSessionService.h"
#import "LCIMUserSystemService.h"
#import "LCIMSignatureService.h"
#import "LCIMSettingService.h"
#import "LCIMUIService.h"
#import "LCIMConversationService.h"
#import "LCIMConversationListService.h"
#import "LCIMServiceDefinition.h"
#import "LCIMConversationViewController.h"
#import "LCIMConversationListViewController.h"
#import "AVIMConversation+LCIMAddition.h"

#endif


#if __has_include(<AVOSCloud/AVOSCloud.h>)
#import <AVOSCloud/AVOSCloud.h>
#import <AVOSCloudIM/AVOSCloudIM.h>
#else
#import "AVOSCloud.h"
#import "AVOSCloudIM.h"
#endif