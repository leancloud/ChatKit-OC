//
//  LCCKUserModelDelegate.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  User Model Delegate.

@import UIKit;

@protocol LCCKUserModelDelegate <NSObject>

@required

/*!
 * @brief The user's id
 */
@property (nonatomic, copy, readonly) NSString *userId;

/*!
 * @brief The user's name
 */
@property (nonatomic, copy, readonly) NSString *name;

/*!
 * @brief User's avator URL
 */
@property (nonatomic, copy, readonly) NSURL *avatorURL;

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatorURL:(NSURL *)avatorURL;
+ (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatorURL:(NSURL *)avatorURL;

@end
