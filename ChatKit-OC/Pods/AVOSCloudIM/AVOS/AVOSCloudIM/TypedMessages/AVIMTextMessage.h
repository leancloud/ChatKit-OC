//
//  AVIMTextMessage.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMTypedMessage.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Text Message.
 */
@interface AVIMTextMessage : AVIMTypedMessage <AVIMTypedMessageSubclassing>

/*!
 创建文本消息。
 @param text － 消息文本.
 @param attributes － 用户附加属性
 */
+ (instancetype)messageWithText:(NSString *)text
                     attributes:(nullable NSDictionary *)attributes;

@end

NS_ASSUME_NONNULL_END
