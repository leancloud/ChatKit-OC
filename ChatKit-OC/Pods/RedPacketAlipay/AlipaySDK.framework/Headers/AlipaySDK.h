//
//  AlipaySDK.h
//  AlipaySDK
//
//  Created by 方彬 on 14-4-28.
//  Copyright (c) 2014年 Alipay. All rights reserved.
//


////////////////////////////////////////////////////////
////////////////version:2.1  motify:2014.12.24//////////
///////////////////Merry Christmas=。=//////////////////
////////////////////////////////////////////////////////


#import "APayAuthInfo.h"
typedef enum {
    ALIPAY_TIDFACTOR_IMEI,
    ALIPAY_TIDFACTOR_IMSI,
    ALIPAY_TIDFACTOR_TID,
    ALIPAY_TIDFACTOR_CLIENTKEY,
    ALIPAY_TIDFACTOR_VIMEI,
    ALIPAY_TIDFACTOR_VIMSI,
    ALIPAY_TIDFACTOR_CLIENTID,
    ALIPAY_TIDFACTOR_APDID,
    ALIPAY_TIDFACTOR_MAX
} AlipayTidFactor;

typedef void(^CompletionBlock)(NSDictionary *resultDic);

@interface AlipaySDK : NSObject<UIAlertViewDelegate>

/**
 *  创建支付单例服务
 *
 *  @return 返回单例对象
 */
+ (AlipaySDK *)defaultService;

/**
 *  支付接口
 *
 *  @param orderStr       订单信息
 *  @param schemeStr      调用支付的app注册在info.plist中的scheme
 *  @param compltionBlock 支付结果回调Block
 */
- (void)payOrder:(NSString *)orderStr
      fromScheme:(NSString *)schemeStr
        callback:(CompletionBlock)completionBlock;

/**
 *  处理钱包或者独立快捷app支付跳回商户app携带的支付结果Url
 *
 *  @param resultUrl 支付结果url，传入后由SDK解析，统一在上面的pay方法的callback中回调
 *  @param completionBlock 跳钱包支付结果回调，保证跳转钱包支付过程中，即使调用方app被系统kill时，能通过这个回调取到支付结果。
 */
- (void)processOrderWithPaymentResult:(NSURL *)resultUrl
                      standbyCallback:(CompletionBlock)completionBlock;

/**
 *  是否已经使用过
 *
 *  @return YES为已经使用过，NO反之
 */
- (BOOL)isLogined;

/**
 *  当前版本号
 *
 *  @return 当前版本字符串
 */
- (NSString *)currentVersion;

/**
 *  当前版本号
 *
 *  @return tid相关信息
 */
- (NSString*)queryTidFactor:(AlipayTidFactor)factor;

/**
 *  測試所用，realse包无效
 *
 *  @param url  测试环境
 */
- (void)setUrl:(NSString *)url;


//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////授权1.0//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  快登授权
 *  @param authInfo        需授权信息
 *  @param completionBlock 授权结果回调
 */
- (void)authWithInfo:(APayAuthInfo *)authInfo
             callback:(CompletionBlock)completionBlock;


/**
 *  处理授权信息Url
 *
 *  @param resultUrl 钱包返回的授权结果url
 *  @param completionBlock 跳授权结果回调，保证跳转钱包授权过程中，即使调用方app被系统kill时，能通过这个回调取到支付结果。
 */
- (void)processAuthResult:(NSURL *)resultUrl
          standbyCallback:(CompletionBlock)completionBlock;

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////授权2.0//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

/**
 *  快登授权2.0
 *
 *  @param infoStr         授权请求信息字符串
 *  @param schemeStr       调用授权的app注册在info.plist中的scheme
 *  @param completionBlock 授权结果回调
 */
- (void)auth_V2WithInfo:(NSString *)infoStr
             fromScheme:(NSString *)schemeStr
               callback:(CompletionBlock)completionBlock;

/**
 *  处理授权信息Url
 *
 *  @param resultUrl 钱包返回的授权结果url
 *  @param completionBlock 跳授权结果回调，保证跳转钱包授权过程中，即使调用方app被系统kill时，能通过这个回调取到支付结果。
 */
- (void)processAuth_V2Result:(NSURL *)resultUrl
             standbyCallback:(CompletionBlock)completionBlock;

@end
