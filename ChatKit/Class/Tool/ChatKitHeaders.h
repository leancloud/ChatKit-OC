//
//  ChatKitHeaders.h
//  LeanCloudIMKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/11.
//  Copyright © 2016年 LeanCloud. All rights reserved.
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

#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCCKSessionService.h>
    #import <ChatKit/LCCKUserSystemService.h>
    #import <ChatKit/LCCKSignatureService.h>
    #import <ChatKit/LCCKSettingService.h>
    #import <ChatKit/LCCKUIService.h>
    #import <ChatKit/LCCKConversationService.h>
    #import <ChatKit/LCCKConversationListService.h>
    #import <ChatKit/LCCKServiceDefinition.h>
    #import <ChatKit/LCCKConversationViewController.h>
    #import <ChatKit/LCCKConversationListViewController.h>
    #import <ChatKit/AVIMConversation+LCCKExtension.h>
    #import <ChatKit/UIImageView+LCCKExtension.h>
    #import <ChatKit/LCCKBaseTableViewController.h>
    #import <ChatKit/LCCKBaseNavigationController.h>
    #import <ChatKit/LCCKMenuItem.h>
    #import <ChatKit/UIImage+LCCKExtension.h>
    #import <ChatKit/NSString+LCCKExtension.h>
    #import <ChatKit/NSObject+LCCKIsFirstLaunch.h>
    #import <ChatKit/LCCKContactListViewController.h>
    #import <ChatKit/LCCKBaseViewController.h>
    #import <ChatKit/LCCKBaseTableViewController.h>
    #import <ChatKit/LCCKBaseNavigationController.h>
    #import <ChatKit/LCCKBaseConversationViewController.h>
    #import <ChatKit/LCCKContact.h>
    #import <ChatKit/AVIMTypedMessage+LCCKExtension.h>
    #import <ChatKit/LCCKInputViewPlugin.h>
    #import <ChatKit/LCCKInputViewPluginPickImage.h>
    #import <ChatKit/LCCKInputViewPluginTakePhoto.h>
    #import <ChatKit/LCCKInputViewPluginLocation.h>
    #import <ChatKit/LCCKAlertController.h>
    #import <ChatKit/NSFileManager+LCCKExtension.h>

#else

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
    #import "AVIMConversation+LCCKExtension.h"
    #import "UIImageView+LCCKExtension.h"
    #import "LCCKBaseTableViewController.h"
    #import "LCCKBaseNavigationController.h"
    #import "LCCKMenuItem.h"
    #import "UIImage+LCCKExtension.h"
    #import "NSString+LCCKExtension.h"
    #import "NSObject+LCCKIsFirstLaunch.h"
    #import "LCCKContactListViewController.h"
    #import "LCCKBaseViewController.h"
    #import "LCCKBaseTableViewController.h"
    #import "LCCKBaseNavigationController.h"
    #import "LCCKBaseConversationViewController.h"
    #import "LCCKContact.h"
    #import "AVIMTypedMessage+LCCKExtension.h"
    #import "LCCKInputViewPlugin.h"
    #import "LCCKInputViewPluginPickImage.h"
    #import "LCCKInputViewPluginTakePhoto.h"
    #import "LCCKInputViewPluginLocation.h"
    #import "LCCKAlertController.h"
    #import "NSFileManager+LCCKExtension.h"

#endif



