//
//  XMNChatMessageCell.h
//  XMNChatExample
//  XMNChatMessageCell 是所有XMNChatCell的父类
//  提供了delegate,messageOwner,messageType属性
//  Created by shscce on 15/11/13.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMNSendImageView.h"
#import "XMNContentView.h"
#import "XMNChatUntiles.h"

@class XMNChatMessageCell;
@protocol XMNChatMessageCellDelegate <NSObject>

- (void)messageCellTappedBlank:(XMNChatMessageCell *)messageCell;
- (void)messageCellTappedHead:(XMNChatMessageCell *)messageCell;
- (void)messageCellTappedMessage:(XMNChatMessageCell *)messageCell;
- (void)messageCell:(XMNChatMessageCell *)messageCell withActionType:(XMNChatMessageCellMenuActionType)actionType;

@end


@interface XMNChatMessageCell : UITableViewCell

/**
 *  显示用户头像的UIImageView
 */
@property (nonatomic, strong) UIImageView *headIV;

/**
 *  显示用户昵称的UILabel
 */
@property (nonatomic, strong) UILabel *nicknameL;

/**
 *  显示用户消息主体的View,所有的消息用到的textView,imageView都会被添加到这个view中 -> XMNContentView 自带一个CAShapeLayer的蒙版
 */
@property (nonatomic, strong) XMNContentView *messageContentV;

/**
 *  显示消息阅读状态的UIImageView -> 主要用于VoiceMessage
 */
@property (nonatomic, strong) UIImageView *messageReadStateIV;

/**
 *  显示消息发送状态的UIImageView -> 用于消息发送不成功时显示
 */
@property (nonatomic, strong) XMNSendImageView *messageSendStateIV;

/**
 *  messageContentV的背景层
 */
@property (nonatomic, strong) UIImageView *messageContentBackgroundIV;


@property (nonatomic, weak) id<XMNChatMessageCellDelegate> delegate;

/**
 *  消息的类型,只读类型,会根据自己的具体实例类型进行判断
 */
@property (nonatomic, assign, readonly) XMNMessageType messageType;

/**
 *  消息的所有者,只读类型,会根据自己的reuseIdentifier进行判断
 */
@property (nonatomic, assign, readonly) XMNMessageOwner messageOwner;

/**
 *  消息群组类型,只读类型,根据reuseIdentifier判断
 */
@property (nonatomic, assign) XMNMessageChat messageChatType;


/**
 *  消息发送状态,当状态为XMNMessageSendFail或XMNMessageSendStateSending时,XMNMessageSendStateIV显示
 */
@property (nonatomic, assign) XMNMessageSendState messageSendState;

/**
 *  消息阅读状态,当状态为XMNMessageUnRead时,XMNMessageReadStateIV显示
 */
@property (nonatomic, assign) XMNMessageReadState messageReadState;


#pragma mark - Public Methods

- (void)setup;
- (void)configureCellWithData:(id)data;

@end
