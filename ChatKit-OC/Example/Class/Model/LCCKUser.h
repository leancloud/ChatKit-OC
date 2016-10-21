//
//  LCCKUser.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/9.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif

@interface LCCKUser : NSObject <LCCKUserDelegate>

/**
 *  检查与 aPerson 是否表示同一对象
 */
- (BOOL)isEqualToUer:(LCCKUser *)user;

- (void)saveToDiskWithKey:(NSString *)key;

+ (id)loadFromDiskWithKey:(NSString *)key;

@end
