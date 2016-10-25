//
//  AVIMSignature.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVIMSignature : NSObject

/**
 *  Signture result signed by server master key.
 */
@property (nonatomic, copy, nullable) NSString *signature;

/**
 *  Timestamp used to construct signature.
 */
@property (nonatomic, assign) int64_t timestamp;

/**
 *  Nonce string used to construct signature
 */
@property (nonatomic, copy, nullable) NSString *nonce;

/**
 *  Error in the course of getting signature from server. Commonly network error. Please set it if any error when getting signature.
 */
@property (nonatomic, strong, nullable) NSError *error;

@end

@protocol AVIMSignatureDataSource <NSObject>
@optional

/*!
 对一个操作进行签名. 注意:本调用会在后台线程被执行
 @param clientId - 操作发起人的 id
 @param conversationId － 操作所属对话的 id
 @param action － 操作的种类，分为：
            "open": 表示登录一个账户
            "start": 表示创建一个对话
            "add": 表示邀请自己或其他人加入对话
            "remove": 表示从对话中踢出部分人
 @attention 这里的 action 并不对应签名中的 action 常量，详细的签名方法请参考文档：https://leancloud.cn/docs/realtime_v2.html#%E5%BC%80%E5%90%AF%E5%AF%B9%E8%AF%9D%E7%AD%BE%E5%90%8D

 @param clientIds － 操作目标的 id 列表
 @return 一个 AVIMSignature 签名对象.
 */
- (AVIMSignature *)signatureWithClientId:(NSString *)clientId
                          conversationId:(nullable NSString *)conversationId
                                  action:(NSString *)action
                       actionOnClientIds:(nullable NSArray *)clientIds;
@end

NS_ASSUME_NONNULL_END
