//
//  RedpacketViewControl.h
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/3/8.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RedpacketMessageModel.h"

typedef NS_ENUM(NSInteger,RPSendRedPacketViewControllerType){
    RPSendRedPacketViewControllerSingle, //点对点红包
    RPSendRedPacketViewControllerGroup,  //普通群红包
    RPSendRedPacketViewControllerMember, //专属红包（包含普通群红包功能）
    RPSendRedPacketViewControllerRand,   //小额度随机红包
};

@protocol RedpacketViewControlDelegate <NSObject>

@optional
/**
 *  获取定向(专属)红包中的群成员列表
 */
- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> * groupMemberList))completionHandle;

/**
 *  广告红包事件触发，需深度合作。具体请联系商务
 *  客服热线: 400-6565-739
 *  业务咨询: BD@yunzhanghu.com
 */
- (void)advertisementRedPacketAction:(NSDictionary *)args;

- (NSArray<RedpacketUserInfo *> *)groupMemberList __deprecated_msg("请用getGroupMemberListCompletionHandle：方法替换");

@end


//  抢红包成功回调
typedef void(^RedpacketGrabBlock)(RedpacketMessageModel *messageModel);

//  接口发送红包消息回调
typedef void(^RedpacketSendBlock)(RedpacketMessageModel *model);


/**
 *  发红包的控制器
 */
@interface RedpacketViewControl : NSObject

/**
 *  当前窗口的会话信息，个人或者群组
 */
@property (nonatomic, strong) RedpacketUserInfo *converstationInfo;

/**
 *  当前的聊天窗口
 */
@property (nonatomic, weak) UIViewController *conversationController;

/**
 *  定向红包获取群成员的代理
 */
@property (nonatomic, weak) id <RedpacketViewControlDelegate> delegate;

/**
 *  零钱接口返回零钱
 */
+ (void)getChangeMoney:(void (^)(NSString *amount))amount;

/**
 *  用户抢红包触发事件
 *
 *  @param messageModel 消息Model
 */
- (void)redpacketCellTouchedWithMessageModel:(RedpacketMessageModel *)messageModel;

/**
 *  设置发送红包，抢红包成功回调
 *
 *  @param grabTouch 抢红包回调
 *  @param sendBlock 发红包回调
 */
- (void)setRedpacketGrabBlock:(RedpacketGrabBlock)grabTouch andRedpacketBlock:(RedpacketSendBlock)sendBlock;

@end


@interface RedpacketViewControl (RedpacketControllers)

/**
 *  零钱页面
 */
+ (UIViewController *)changeMoneyController;

/**
 *  零钱明细页面
 */
+ (UIViewController *)changeMoneyListController;

/**
 *  生成红包页面
 *
 *  @param rpType 红包页面类型
 *  @param count  群红包群人数， 如果是点对点红包传入0
 */
- (UIViewController *)redPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;

/**
 *  弹出发红包页面
 *
 *  @param rpType 红包页面类型
 *  @param count  群红包群人数， 如果是点对点红包传入0
 */
- (void)presentRedPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;

/**
 *  弹出转账界面
 *
 *  @param userInfo 红包页面类型
 */
- (void)presentTransferViewControllerWithReceiver:(RedpacketUserInfo *)userInfo;

/**
 *  弹出转账详情控制器
 */
- (void)presentTransferDetailViewController:(RedpacketMessageModel *)model;

/**
 *  弹出零钱页面
 */
- (void)presentChangeMoneyViewController;


@end


/*
 * 以下方法不再使用，请替换新方法
 */
@interface RedpacketViewControl (Deprecated_Nonfunctional)

- (UIViewController *)redpacketViewController __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");
- (UIViewController *)redPacketMoreViewControllerWithGroupMembers:(NSArray *)groupMemberArray __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");
- (void)presentRedPacketMoreViewControllerWithGroupMembers:(NSArray *)groupMemberArray __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");
- (void)presentRedPacketViewController __deprecated_msg("请用presentRedPacketViewControllerWithType: memberCount:替换");

@end
