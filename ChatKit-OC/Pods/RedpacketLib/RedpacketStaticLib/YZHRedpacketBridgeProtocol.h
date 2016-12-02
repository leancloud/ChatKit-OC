//
//  YZHRedpacketBridgeProtocol.h
//  RedpacketLib
//
//  Created by Mr.Yang on 16/4/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#ifndef YZHRedpacketBridgeProtocol_h
#define YZHRedpacketBridgeProtocol_h


@class RedpacketRegisitModel;

//  初始化参数需要开发者回调， 如果初始化失败请传入nil
typedef void (^FetchRegisitParamBlock)(RedpacketRegisitModel *model);

@class RedpacketUserInfo;

@protocol YZHRedpacketBridgeDataSource <NSObject>

/** 主动获取当前登录的用户信息 */
- (RedpacketUserInfo *)redpacketUserInfo;

@end


@protocol YZHRedpacketBridgeDelegate <NSObject>

@optional

- (void)redpacketError:(NSString *)error withErrorCode:(NSInteger)code __deprecated_msg("方法已经停止使用，请使用redpacketFetchRegisitParam: withError:");

@required

/** 使用红包服务时，如果红包Token不存在或者过期，则回调此方法，需要在RedpacketRegisitModel生成后，通过fetchBlock回传给红包SDK
  * 如果错误error不为空， 1. 如果是环信IM，则刷新环信ImToken 2.如果是签名方式， 则刷新签名.
 */
- (void)redpacketFetchRegisitParam:(FetchRegisitParamBlock)fetchBlock withError:(NSError *)error;

@end


#endif /* YZHRedpacketBridgeProtocol_h */
