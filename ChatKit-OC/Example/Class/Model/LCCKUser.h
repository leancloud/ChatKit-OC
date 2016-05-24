//
//  LCCKUser.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
@interface LCCKUser : AVUser <LCCKUserModelDelegate, LCCKUserModelDelegate, NSCoding, NSCopying>

/*!
 * @brief The user's id
 */
@property (nonatomic, copy, readonly) NSString *userId;

/*!
 * @brief The user's name
 */
@property (nonatomic, copy, readonly) NSString *name;

/*!
 * @brief String of the user's avator URL
 * @attention Its type is NSString, not NSURL
 */
@property (nonatomic, copy, readonly) NSURL *avatorURL;

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatorURL:(NSURL *)avatorURL;
+ (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatorURL:(NSURL *)avatorURL;

/**
 *  检查与 aPerson 是否表示同一对象
 */
- (BOOL)isEqualToUer:(LCCKUser *)user;

- (void)saveToDiskWithKey:(NSString *)key;

+ (id)loadFromDiskWithKey:(NSString *)key;

@end
