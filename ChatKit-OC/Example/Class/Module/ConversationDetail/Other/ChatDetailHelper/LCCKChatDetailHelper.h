//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit

#import <Foundation/Foundation.h>
#import "LCCKSettingGroup.h"

@class LCCKUser, AVIMConversation;

@interface LCCKChatDetailHelper : NSObject

- (NSMutableArray *)chatDetailDataBySingleInfo:(AVIMConversation *)singleInfo;

- (NSMutableArray *)chatDetailDataByGroupInfo:(AVIMConversation *)groupInfo;

@end
