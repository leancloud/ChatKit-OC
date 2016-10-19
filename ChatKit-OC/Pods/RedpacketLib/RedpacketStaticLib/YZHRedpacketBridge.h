//
//  RedpacketUserAccount.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/1.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YZHRedpacketBridgeProtocol.h"


@interface YZHRedpacketBridge : NSObject

@property (nonatomic, weak) id <YZHRedpacketBridgeDelegate> delegate;

@property (nonatomic, weak) id <YZHRedpacketBridgeDataSource>dataSource;

/**
 *  是否是调试模式, 默认为NO
 */
@property (nonatomic, assign)   BOOL isDebug;

/**
 *  支付宝回调当前APP时的URL Scheme, 默认为当前App的Bundle Identifier
 */
@property (nonatomic, copy)  NSString *redacketURLScheme;

+ (YZHRedpacketBridge *)sharedBridge;

@end


@interface YZHRedpacketBridge (Easemob)

/**
 *  通过环信imToken的方式获取Token
 *
 *  @param appKey    商户在环信申请的AppKey
 *  @param appUserId 用户在App的用户ID， 默认与imUserId相同
 *  @param imToken   环信IM的Token
 */
- (NSString *)configWithAppKey:(NSString *)appKey
                     appUserId:(NSString *)appUserId
                       imToken:(NSString *)imToken;

@end


@interface YZHRedpacketBridge (SignMethod)

/**
 *  签名无需每次都要请求，请求前请先调用下列方法判断是否需要更新签名
 */
- (BOOL)isNeedUpdateSignWithUserId:(NSString *)userId;

/**
 *  通过签名的方式获取Token (以下参数的获取方式见RestAPI集成文档)
 *
 *  @param sign
 *  @param partner
 *  @param appUserid  用户在App的用户ID
 *  @param timeStamp  时间戳
 */
- (NSString *)configWithSign:(NSString *)sign
                     partner:(NSString *)partner
                   appUserId:(NSString *)appUserid
                   timestamp:(NSString *)timestamp;
@end


@interface YZHRedpacketBridge (RequestToken)

/**
 *  同步Token(开发者无需调用)
 */
- (void)reRequestRedpacketUserToken:(void(^)(NSInteger code, NSString *msg))tokenRequestCompletionBlock;

@end


/**
 *  已经不再使用的API，请注意修改(可以将以下内容直接删除)
 */
@interface YZHRedpacketBridge (Deprecated)

/**
 *  商户名称
 */
@property (nonatomic, copy)  NSString *redpacketOrgName __deprecated_msg("方法已经停用，请通过云账户后端进行配置");

/**
 *  用户退出需要清空Token
 */
- (void)redpacketUserLoginOut __deprecated_msg("方法已经不需要调用, SDK根据用户变更和Token过期自动切换");

/**
 *  签名注册Token
 */
- (void)configWithSign:(NSString *)sign
                     partner:(NSString *)partner
                   appUserId:(NSString *)appUserid
                   timeStamp:(long)timeStamp __deprecated_msg("方法命名不规范，已经停用, 请使用上边的方法");

@end
