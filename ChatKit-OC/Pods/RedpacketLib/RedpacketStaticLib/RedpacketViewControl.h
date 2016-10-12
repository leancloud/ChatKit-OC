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
    RPSendRedPacketViewControllerMember, //包含专属红包的群红包
};

@protocol RedpacketViewControlDelegate <NSObject>

@optional
- (NSArray<RedpacketUserInfo *> *)groupMemberList __attribute__((deprecated("请用getGroupMemberListCompletionHandle：方法替换")));
- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> * groupMemberList))completionHandle;

@end

//  抢红包成功回调
typedef void(^RedpacketGrabBlock)(RedpacketMessageModel *messageModel);

//  环信接口发送红包消息回调
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
 *  定向红包返回时的代理
 */
@property (nonatomic, weak) id <RedpacketViewControlDelegate> delegate;

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

#pragma mark - Controllers

- (UIViewController *)redpacketViewController __attribute__((deprecated("请用presentRedPacketViewControllerWithType: memberCount:替换")));
- (UIViewController *)redPacketMoreViewControllerWithGroupMembers:(NSArray *)groupMemberArray __attribute__((deprecated("请用presentRedPacketViewControllerWithType: memberCount:替换")));
- (void)presentRedPacketMoreViewControllerWithGroupMembers:(NSArray *)groupMemberArray __attribute__((deprecated("请用presentRedPacketViewControllerWithType: memberCount:替换")));
- (void)presentRedPacketViewController __attribute__((deprecated("请用presentRedPacketViewControllerWithType: memberCount:替换")));

/**
 *  弹出红包控制器
 *
 *  @param rpType 红包页面类型
 *  @param count  群红包群人数
 */
- (void)presentRedPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;
/**
 *  生成红包Controller
 *
 *  @param rpType 红包页面类型
 *  @param count  群红包群人数
 *
 *  @return 红包Controller
 */
- (UIViewController *)redPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;

/**
 *  生成转账Controller
 *  
 *  @param userInfo 用户相关属性
 *
 *  @return 转账Controller
 */
- (void)presentTransferViewControllerWithReceiver:(RedpacketUserInfo *)userInfo;

/**
 *  生成转账DetailController
 *
 *
 *
 *  @return 转账Controller
 */
- (void)presentTransferDetailViewController:(RedpacketMessageModel *)model;

/**
 *  零钱页面
 *
 *  @return 零钱页面，App可以放在需要的位置
 */
+ (UIViewController *)changeMoneyController;

/**
 *  零钱明细页面
 *
 *  @return 零钱明细页面，App可以放在需要的位置
 */
+ (UIViewController *)changeMoneyListController;

#pragma mark - ShowViewControllers

/**
 *  Present的方式显示零钱页面
 */
- (void)presentChangeMoneyViewController;

/**
 *  零钱接口返回零钱
 *
 *  @param amount 零钱金额
 */
+ (void)getChangeMoney:(void (^)(NSString *amount))amount;

@end
