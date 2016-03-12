//
//  LCIMSessionService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/3/1.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

@import Foundation;
@import UIKit;
#import "LCIMServiceDefinition.h"

/*!
 * LCIMSessionService error demain
 */
FOUNDATION_EXTERN NSString *const LCIMSessionServiceErrorDemain;

@interface LCIMSessionService : NSObject <LCIMSessionService>

@property (nonatomic, copy, readonly) NSString *clientId;
/*!
 * AVIMClient 实例
 */
@property (nonatomic, strong, readonly) AVIMClient *client;

/**
 *  是否和聊天服务器连通
 */
@property (nonatomic, assign, readonly) BOOL connect;

+ (instancetype)sharedInstance;

@end
