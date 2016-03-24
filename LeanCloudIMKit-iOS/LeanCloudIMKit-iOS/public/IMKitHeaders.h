//
//  IMKitHeaders.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/11.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#if __has_include(<LCIMKit/LCIMKit.h>)

FOUNDATION_EXPORT double LCIMKitVersionNumber;
FOUNDATION_EXPORT const unsigned char LCIMKitVersionString[];
#import <AVOSCloud/AVOSCloud.h>
#import <AVOSCloudIM/AVOSCloudIM.h>

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
#import "LCIMTableViewRowAction.h"

#endif