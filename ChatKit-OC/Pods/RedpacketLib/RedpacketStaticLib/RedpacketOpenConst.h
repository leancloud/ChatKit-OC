//
//  RedpacketOpenConst.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/17.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


#pragma mark - RedpacketNotifaction

/**
 *  支付宝支付完成通知
 */
UIKIT_EXTERN NSString *const RedpacketAlipayNotifaction;

#pragma mark - RedpacketView

/**
 * 红包的名字（例如：云红包）
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketOrgName;

/**
 *  红包的祝福语
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketGreeting;

/**
 *  红包接收消息的Cell标记
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketSign;

/**
 *  是否是红包的标记
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketTakenMessageSign;

/**
 *  红包的发送方ID
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketSenderId;

/**
 *  红包的发送方
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketSenderNickname;

/**
 *  红包的接收方ID
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketReceiverId;

/**
 *  红包的接收方
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketReceiverNickname;

/**
 *  红包ID
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketID;

/**
 *  提示收到群红包的 cmd
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedapcketCmd;

/**
 *  定向红包的Type类型
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedapcketToAnyone;

/**
 *  转账
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketTransfer;

/**
 *  转账时间
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketTransferTime;

/**
 *  转账金额
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketTransferAmout;

/**
 *  定向红包的接收者id
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedapcketToReceiver;

/**
 *  红包抢完后的透传消息是通过点对点Cmd消息发送，所以需要带上红包所在的群组ID
 */
UIKIT_EXTERN NSString *const RedpacketKeyRedpacketCmdToGroup;

