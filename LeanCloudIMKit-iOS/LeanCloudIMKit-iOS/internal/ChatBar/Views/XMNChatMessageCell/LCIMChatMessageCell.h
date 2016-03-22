//
//  LCIMChatMessageCell.h
//  LCIMChatExample
//  LCIMChatMessageCell 是所有LCIMChatCell的父类
//  提供了delegate,messageOwner,messageType属性
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/13.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LCIMSendImageView.h"
#import "LCIMContentView.h"
#import "LCIMChatUntiles.h"
#import "LCIMMessage.h"

@class LCIMChatMessageCell;

@protocol LCIMChatMessageCellDelegate <NSObject>

- (void)messageCellTappedBlank:(LCIMChatMessageCell *)messageCell;
- (void)messageCellTappedHead:(LCIMChatMessageCell *)messageCell;
- (void)messageCellTappedMessage:(LCIMChatMessageCell *)messageCell;
- (void)messageCell:(LCIMChatMessageCell *)messageCell withActionType:(LCIMChatMessageCellMenuActionType)actionType;

@end

@interface LCIMChatMessageCell : UITableViewCell

/**
 *  显示用户头像的UIImageView
 */
@property (nonatomic, strong) UIImageView *headImageView;

/**
 *  显示用户昵称的UILabel
 */
@property (nonatomic, strong) UILabel *nicknameLabel;

/**
 *  显示用户消息主体的View,所有的消息用到的textView,imageView都会被添加到这个view中 -> LCIMContentView 自带一个CAShapeLayer的蒙版
 */
@property (nonatomic, strong) LCIMContentView *messageContentView;

/**
 *  显示消息阅读状态的UIImageView -> 主要用于VoiceMessage
 */
@property (nonatomic, strong) UIImageView *messageReadStateImageView;

/**
 *  显示消息发送状态的UIImageView -> 用于消息发送不成功时显示
 */
@property (nonatomic, strong) LCIMSendImageView *messageSendStateImageView;

/**
 *  messageContentView的背景层
 */
@property (nonatomic, strong) UIImageView *messageContentBackgroundImageView;


@property (nonatomic, weak) id<LCIMChatMessageCellDelegate> delegate;

/**
 *  消息的类型,只读类型,会根据自己的具体实例类型进行判断
 */
@property (nonatomic, assign, readonly) LCIMMessageType messageType;

/**
 *  消息的所有者,只读类型,会根据自己的reuseIdentifier进行判断
 */
@property (nonatomic, assign, readonly) LCIMMessageOwner messageOwner;

/**
 *  消息群组类型,只读类型,根据reuseIdentifier判断
 */
@property (nonatomic, assign) LCIMMessageChat messageChatType;

/**
 *  消息发送状态,当状态为LCIMMessageSendFail或LCIMMessageSendStateSending时,LCIMmessageSendStateImageView显示
 */
@property (nonatomic, assign) LCIMMessageSendState messageSendState;

/**
 *  消息阅读状态,当状态为LCIMMessageUnRead时,LCIMmessageReadStateImageView显示
 */
@property (nonatomic, assign) LCIMMessageReadState messageReadState;


#pragma mark - Public Methods

- (void)setup;
- (void)configureCellWithData:(LCIMMessage *)message;

@end
