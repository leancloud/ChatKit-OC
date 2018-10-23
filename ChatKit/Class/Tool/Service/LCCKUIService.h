//
//  LCCKUIService.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKServiceDefinition.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

/**
 *  UIService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCCKUIServiceErrorDomain;

@interface LCCKUIService : LCCKSingleton <LCCKUIService>

/*!
 *  未读数发生变化
 *  @param aCount 总的未读数
 */
typedef void(^LCCKUnreadCountChangedBlock)(NSInteger count);
@property (nonatomic, copy, readonly) LCCKUnreadCountChangedBlock unreadCountChangedBlock;
- (void)setUnreadCountChangedBlock:(LCCKUnreadCountChangedBlock)unreadCountChangedBlock;
//TODO:
/**
 *  新消息通知
 */
typedef void(^LCCKOnNewMessageBlock)(NSString *senderId, NSString *content, NSInteger type, NSDate *time);

@end
