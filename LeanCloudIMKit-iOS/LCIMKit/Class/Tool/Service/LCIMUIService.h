//
//  LCIMUIService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

/**
 *  UIService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCIMUIServiceErrorDomain;

@interface LCIMUIService : LCCKSingleton <LCIMUIService>

/**
 *  未读数发生变化
 *  @param aCount 总的未读数
 */
typedef void(^LCIMUnreadCountChangedBlock)(NSInteger count);
@property (nonatomic, copy, readonly) LCIMUnreadCountChangedBlock unreadCountChangedBlock;
- (void)setUnreadCountChangedBlock:(LCIMUnreadCountChangedBlock)unreadCountChangedBlock;
//TODO:
/**
 *  新消息通知
 */
typedef void(^LCIMOnNewMessageBlock)(NSString *senderId, NSString *content, NSInteger type, NSDate *time);

@end
