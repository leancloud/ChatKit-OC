//
//  RedpacketErrorCode.h
//  RedpacketRequestDataLib
//
//  Created by Mr.Yang on 16/5/6.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//



typedef enum{
    RedpacketSuccessful        = 0000,  /*操作成功*/
    RedpacketOtherError        = 100,   /*其它错误操作导致失败*/
    RedpacketParamInsuf        = 1000,  /*请求参数不足或者格式不正确*/

    RedpacketMobilIllegal      = 1001,  /*手机号格式不正确*/
    RedpacketIDCardIllegal,             /*身份证格式不正确*/
    RedpacketNameIllegal,               /*姓名不合法(不能是汉字)*/
    RedpacketRefInvalid,                /*查询无此ref对应的验证码*/
    RedpacketCaptchaInvalid,             /*验证码不匹配*/
    RedpacketCardNoInvalid,              /*卡号格式不正确*/

    RedpacketSMSFalied         = 1010,  /*发送短信验证码失败*/
    RedpacketIDCardExisted,             /*身份证号已经存在，但是手机号不匹配*/
    RedpacketMobileExisted,             /*手机号已经存在, 但是身份证号不匹配*/
    RedpacketDuserExisted,              /*此用户已经实名认证过，不能再认证*/
    RedpacketRealExisted,               /*此实名信息已经被其他用户认证*/
    RedpacketSMSOverMuch,               /*此手机号或者用户发送短信次数过多*/
    RedpacketIDCardOverMuch,             /*实名认证请求次数过多*/

    RedpacketVerifyFailed     = 1020,   /*实名认证失败*/

    RedpacketSubBankNotExisted = 2011,  /*联行不存在*/
    RedpacketCardBinNotExisted,         /*该银行卡不存在*/
    RedapcketBankNotSupported,          /*暂不支持此银行*/
    RedpacketCardBoundByOther,          /*此卡已被他人绑定，请换一张*/
    RedpacketCardBoundByOwner,          /*磁卡已经被验证成功*/
    RedpacketCardBoundAndCorrect,       /*此卡已经绑过，输入卡信息正确*/
    RedpacketCardBoundAndInCorrect,     /*此卡已经被别人绑过,输入卡信息不正确*/
    RedpacketNewCardNoMatch,            /*请使用本人银行卡*/

    RedpacketBindCardFailed    = 2020,  /*绑卡失败*/

    RedpacketHBIDIllegal       = 3001,  /*红包ID不合法*/
    RedpacketHBMoneyInsuf,              /*零钱不足，请充值*/
    RedpacketHBPayPWDFailed,            /*支付密码不正确*/
    RedpacketHBMsgTooLong,              /*留言过长*/
    RedpacketHBPayPWDErrorLimit,        /*尝试次数已经达到上限，请明天再试*/
    RedpacketHBCountIllegal,            /*红包数量不合法*/
    RedpacketHBAvgLess001,              /*人均小于0.01元*/
    RedpacketHBCountTooLarge,           /*您发的红包个数太多*/
    RedpacketHBAvgAmountTooLarge,       /*人均金额过大*/

    RedpacketHBExpried         = 3011,  /*红包已过期*/
    RedpacketHBReceiverError,           /*此红包不属于您*/
    RedpacketHBCompleted,               /*此红包已经被领取*/

    RedpacketHBQuotaNoPayPWD   = 3021,  /*无密码支付剩余额度提示*/
    RedpacketHBQuotaDay ,                /*当日发红包限额提示*/

    RedpacketHBOcciOvermuch    = 9,     /*接口调用频率太高，请稍候重试*/

    RedpacketHBDeviceIDInvalid = 101    /*设备号无效*/


}RedpacketErrorCode;
