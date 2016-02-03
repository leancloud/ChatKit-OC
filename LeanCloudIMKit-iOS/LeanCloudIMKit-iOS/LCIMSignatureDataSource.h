//
//  LCIMSignatureDataSource.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//
#import <AVOSCloudIM/AVOSCloudIM.h>

/**
 * You can implement `-signatureWithClientId:conversationId:action:actionOnClientIds:` to let LeanCloudIMKit pin signature to these actions: open, start(create conversation), kick, invite.
 */

@protocol LCIMSignatureDataSource <NSObject>

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
                          conversationId:(NSString *)conversationId
                                  action:(NSString *)action
                       actionOnClientIds:(NSArray *)clientIds;
@end
