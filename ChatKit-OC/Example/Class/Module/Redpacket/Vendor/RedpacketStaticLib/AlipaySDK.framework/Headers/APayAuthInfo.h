//
//  APAuthInfo.h
//  AliSDKDemo
//
//  Created by 方彬 on 14-7-18.
//  Copyright (c) 2014年 Alipay.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APayAuthInfo : NSObject

@property(nonatomic, copy)NSString *appID;
@property(nonatomic, copy)NSString *pid;
@property(nonatomic, copy)NSString *redirectUri;

/**
 *  初始化AuthInfo
 *
 *  @param appIDStr     应用ID
 *  @param productIDStr 产品码 该商户在aboss签约的产品,用户获取pid获取的参数
 *  @param pidStr       商户ID   可不填
 *  @param uriStr       授权的应用回调地址  比如：alidemo://auth
 *
 *  @return authinfo实例
 */
- (id)initWithAppID:(NSString *)appIDStr
                pid:(NSString *)pidStr
        redirectUri:(NSString *)uriStr;

- (NSString *)description;
- (NSString *)wapDescription;
@end
