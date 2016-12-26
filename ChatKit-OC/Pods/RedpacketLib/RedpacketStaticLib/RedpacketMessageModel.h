//
//  RedpacketMessageModel.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RedpacketOpenConst.h"

typedef NS_ENUM(NSInteger, RedpacketMessageType) {

    RedpacketMessageTypeRedpacket = 1001,           /***  红包消息*/
    RedpacketMessageTypeTedpacketTakenMessage,      /***  红包被抢的消息*/
    RedpacketMessageTypeTransfer                    /***  转账消息*/
};

typedef NS_ENUM(NSInteger, RedpacketType) {
    
    RedpacketTypeSingle = 2001,     /***  点对点红包*/
    RedpacketTypeGroup,             /***  群组红包 (暂时留存)*/
    RedpacketTypeRand,              /***  拼手气红包*/
    RedpacketTypeAvg,               /***  普通红包*/
    RedpacketTypeRandpri,           /***  拼手气普通显示（一般用于系统发放）*/
    RedpacketTypeMember,            /***  定向红包 （专属红包，目前支持一人）*/
    RedpacketTypeAdvertisement,     /***  广告红包*/
    RedpacketTransfer,              /***  转账*/
    RedpacketTypeAmount             /***  小额随机红包*/
};

typedef NS_ENUM(NSInteger, RedpacketStatusType) {
    
    RedpacketStatusTypeCanGrab = 0,         /***  红包可以抢*/
    RedpacketStatusTypeGrabFinish = 1,      /***  红包被抢完*/
    RedpacketStatusTypeOutDate = -1         /***  红包已过期*/

};

@interface RedpacketUserInfo : NSObject <NSCopying>
/**
 *  用户的Id,
 */
@property (nonatomic, copy) NSString *userId;
/**
 *  用户的昵称,
 */
@property (nonatomic, copy) NSString *userNickname;
/**
 *  用户名过长会发生截断,此处获取的是用户的原昵称
 */
@property (nonatomic, copy, readonly) NSString *userNicknameOrigin;
/**
 *  用户的头像地址,
 */
@property (nonatomic, copy) NSString *userAvatar;
//@property (nonatomic, assign) BOOL isGroup;

@end


@interface RedpacketViewModel : NSObject <NSCopying>

/**
 *  红包金额
 */
@property (nonatomic, copy) NSString *redpacketMoney;
/**
 *  群红包类型， 随机，或者平均
 */
@property (nonatomic, copy) NSString *groupRedpacketType;
/**
 *  红包个数
 */
@property (nonatomic, assign) NSInteger redpacketCount;
/**
 *  定向红包，红包接收者ID
 */
@property (nonatomic, copy) NSString *toReceiverDuid;

@property (nonatomic, copy) NSString *redpacketGreeting;
@property (nonatomic, copy) NSString *redpacketOrgName;
@property (nonatomic, copy) NSString *tranferTime;

//未来定制化留存
@property (nonatomic, copy) NSString *redpacketIcon;
@property (nonatomic, copy) NSString *redpacketOrgIcon;

@end

/**
 *  红包消息
 */
@interface RedpacketMessageModel : NSObject <NSCopying>

/**
 *  当前聊天窗口(环信Cmd消息透传时传递当前会话窗口)
 */
@property (nonatomic, copy) NSString *conversationID;

/**
 *  红包ID
 */
@property (nonatomic, copy) NSString *redpacketId;

/**
 *  红包消息类型，红包消息， 红包被领取的消息
 */
@property (nonatomic, assign) RedpacketMessageType messageType;

/**
 *  红包的类型
 */
@property (nonatomic, assign) RedpacketType redpacketType;

/**
 *  红包的类型
 */
@property (nonatomic, assign) RedpacketStatusType redpacketStatusType;

/**
 *  红包详情里我抢到的金额
 */
@property (nonatomic,assign) NSString *myAmount;

/**
 *  当前用户是否是红包的发送者
 */
@property (nonatomic, readonly) BOOL isRedacketSender;

/**
 *  当前用户信息
 */
@property (nonatomic, readonly) RedpacketUserInfo *currentUser;

/**
 *  红包发送者信息
 */
@property (nonatomic, strong) RedpacketUserInfo *redpacketSender;

/**
 *  红包接受者信息
 */
@property (nonatomic, strong) RedpacketUserInfo *redpacketReceiver;

/**
 *  专属红包接收者消息
 */
@property (nonatomic, strong) RedpacketUserInfo *toRedpacketReceiver;

/**
 *  红包视图相关信息
 */
@property (nonatomic, strong) RedpacketViewModel *redpacket;

/**
 *  红包详情页使用字典信息
 */
@property (nonatomic, strong)   NSDictionary *redpacketDetailDic;

/**
 *  是否红包相关信息
 *
 *  @param redpacketDic 红包消息，通过IM传递的信息字典
 *
 *  @return @YES 跟红包相关  @NO 跟红包无关
 */
+ (BOOL)isRedpacketRelatedMessage:(NSDictionary *)redpacketDic;

/**
 *  是否是红包信息
 *
 *  @param redpacketDic 红包消息，通过IM传递的信息字典
 *
 *  @return YES 是红包信息
 */
+ (BOOL)isRedpacket:(NSDictionary *)redpacketDic;

/**
 *  是否是红包被抢的消息
 *
 *  @param redpacketDic
 *
 *  @return
 */
+ (BOOL)isRedpacketTakenMessage:(NSDictionary *)redpacketDic;

/**
 *  是否是转账消息
 */
+ (BOOL)isRedpacketTransferMessage:(NSDictionary *)redpacketDic;

/**
 *  字典转换成红包消息Model
 *
 *  @param redpacketDic 红包字典，在IM消息中传播的字典
 *
 *  @return 红包消息Model
 */
+ (RedpacketMessageModel *)redpacketMessageModelWithDic:(NSDictionary *)redpacketDic;

/**
 *   解析在IM消息中传播的字典
 *
 *  @param repacketDic 在IM消息中传播的字典
 */
- (void)configWithRedpacketDic:(NSDictionary *)repacketDic;

/**
 *  红包消息转换成字典
 *
 *  @return 在IM消息中传播的字典
 */
- (NSDictionary *)redpacketMessageModelToDic;

/**
 *  红包类型赋值
 *
 *  @param groupType 红包类型字符串
 */
- (void)redpacketTypeVoluationWithGroupType:(NSString *)groupType;

@end
