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


typedef NS_ENUM(NSInteger,RPRedpacketControllerType){
    RPRedpacketControllerTypeSingle,    //点对点红包
    RPRedpacketControllerTypeRand,      //小额度随机红包
    RPRedpacketControllerTypeTransfer,  //转账
    RPRedpacketControllerTypeGroup,     //群红包
};

typedef void(^RedpacketSendBlock)(RedpacketMessageModel *model);
typedef void(^RedpacketMemberListFetchBlock)(NSArray<RedpacketUserInfo *> * groupMemberList);
typedef void (^RedpacketMemberListBlock)(RedpacketMemberListFetchBlock completionHandle);
typedef void(^RedpacketAdvertisementAction)(NSDictionary *args);
typedef void(^RedpacketGrabBlock)(RedpacketMessageModel *messageModel);


/** 发红包的控制器, 开发者无需持有此对象 */
@interface RedpacketViewControl : NSObject

/*!
 抢红包方法
 
 @required
        @param messageModel 红包相关信息
        @param fromViewController 当前页面控制器
        @param grabTouch          抢红包成功后的回调
 
 @optional
        @param advertisementAction 广告红包用户行为回调(广告红包后才需要传)
 */
+ (void)redpacketTouchedWithMessageModel:(RedpacketMessageModel *)messageModel
                     fromViewController:(UIViewController *)fromViewController
                      redpacketGrabBlock:(RedpacketGrabBlock)grabTouch
                     advertisementAction:(RedpacketAdvertisementAction)advertisementAction;

/*!
 发送红包方法
 
 @required
        @param controllerType   发送红包类型（点对点红包 小额度红包 转账红包 只限在单人聊天中使用）
        @param fromeController  当前页面控制器
        @param count            群成员人数（可传0）
        @param receiver         红包接受者信息 (群组时接收者ID为当前会话ID，头像，昵称不传)
        @param sendBlock        红包发送成功后的回调
 
 @optional
        @param memberBlock      专属红包获取群成员回调（非专属红包不传）
 */
+ (void)presentRedpacketViewController:(RPRedpacketControllerType)controllerType
                       fromeController:(UIViewController *)fromeController
                      groupMemberCount:(NSInteger)count
                 withRedpacketReceiver:(RedpacketUserInfo *)receiver
                       andSuccessBlock:(RedpacketSendBlock)sendBlock
         withFetchGroupMemberListBlock:(RedpacketMemberListBlock)memberBlock;

/** 弹出零钱页面控制器 */
+ (void)presentChangePocketViewControllerFromeController:(UIViewController *)viewController;

/** 零钱页面控制器 */
+ (UIViewController *)changePocketViewController;

/** 零钱接口返回零钱 */
+ (void)getChangeMoney:(void (^)(NSString *amount))amount;

@end
