//
//  LCCKUserDelegate.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  User Model Delegate.

@import UIKit;

@protocol LCCKUserDelegate <NSObject, NSCopying, NSCoding>

@required

/*!
 * @brief The user's id in your own APP user system.
 */
@property (nonatomic, copy, readonly) NSString *userId;

/*!
 * @brief The user's name.
 */
@property (nonatomic, copy, readonly) NSString *name;

/*!
 * @brief User's avatar URL.
 */
@property (nonatomic, copy, readonly) NSURL *avatarURL;

/*!
 * @brief The user's id in LeanCloud SDK, it may be equal to `userId`.
 */
@property (nonatomic, copy, readwrite) NSString *clientId;

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId;
+ (instancetype)userWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL clientId:(NSString *)clientId;

@optional

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL;
+ (instancetype)userWithUserId:(NSString *)userId name:(NSString *)name avatarURL:(NSURL *)avatarURL;

- (instancetype)initWithClientId:(NSString *)clientId;
+ (instancetype)userWithClientId:(NSString *)clientId;

@end
