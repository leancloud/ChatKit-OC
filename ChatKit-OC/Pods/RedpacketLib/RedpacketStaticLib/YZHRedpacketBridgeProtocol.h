//
//  YZHRedpacketBridgeProtocol.h
//  RedpacketLib
//
//  Created by Mr.Yang on 16/4/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#ifndef YZHRedpacketBridgeProtocol_h
#define YZHRedpacketBridgeProtocol_h


@class RedpacketUserInfo;

@protocol YZHRedpacketBridgeDataSource <NSObject>

/**
 *  主动获取App用户的用户信息
 *
 *  @return 用户信息Info
 */
- (RedpacketUserInfo *)redpacketUserInfo;

@end


@protocol YZHRedpacketBridgeDelegate <NSObject>
@required
/**
 *  SDK错误处理代理
 *
 *  @param error 错误内容
 *  @param code  错误码
 *  @discussion
    1.通过ImToken获取红包Token, 红包Token过期后，请求红包Token时，ImToken过期触发回调，刷新ImToken后，重新注册红包Token。
    2.通过Sign获取红包Token， 红包Token过期后，直接触发。
    错误码： 20304  环信IMToken验证错误
    错误码： 1001 Token相关错误
 */
- (void)redpacketError:(NSString *)error withErrorCode:(NSInteger)code;

@end


#endif /* YZHRedpacketBridgeProtocol_h */
