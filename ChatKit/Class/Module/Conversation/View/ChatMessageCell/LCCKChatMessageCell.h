//
//  LCCKChatMessageCell.h
//  LCCKChatExample
//  LCCKChatMessageCell 是所有LCCKChatCell的父类
//  提供了delegate,messageOwner,messageType属性
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/13.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCCKMessageSendStateView.h"
#import "LCCKContentView.h"
#import "LCCKConstants.h"
#import "LCCKMessage.h"
#import "LCCKSettingService.h"
#import "NSString+LCCKExtension.h"

#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
#import <AVOSCloudIM/AVOSCloudIM.h>

#if __has_include(<MLLabel/MLLinkLabel.h>)
    #import <MLLabel/MLLinkLabel.h>
#else
    #import "MLLinkLabel.h"
#endif

@class LCCKChatMessageCell;

@protocol LCCKChatMessageCellSubclassing <NSObject>
@required
/*!
 子类实现此方法用于返回该类对应的消息类型
 @return 消息类型
 */
+ (AVIMMessageMediaType)classMediaType;
@end

@protocol LCCKChatMessageCellDelegate <NSObject>

- (void)messageCellTappedBlank:(LCCKChatMessageCell *)messageCell;
- (void)messageCellTappedHead:(LCCKChatMessageCell *)messageCell;
- (void)messageCellTappedMessage:(LCCKChatMessageCell *)messageCell;
- (void)textMessageCellDoubleTapped:(LCCKChatMessageCell *)messageCell;
- (void)resendMessage:(LCCKChatMessageCell *)messageCell;
- (void)avatarImageViewLongPressed:(LCCKChatMessageCell *)messageCell;
- (void)messageCell:(LCCKChatMessageCell *)messageCell didTapLinkText:(NSString *)linkText linkType:(MLLinkType)linkType;
- (void)fileMessageDidDownload:(LCCKChatMessageCell *)messageCell;
- (void)modifyMessage:(LCCKChatMessageCell *)messageCell newMessage:(LCCKMessage *)newMessage callback:(void (^)(BOOL, NSError *))callback;
- (void)recallMessage:(LCCKChatMessageCell *)messageCell callback:(void (^)(BOOL, NSError *))callback;

@end

@interface LCCKChatMessageCell : UITableViewCell

+ (void)registerCustomMessageCell;
+ (void)registerSubclass;
- (void)addGeneralView;
@property (nonatomic, strong, readonly) LCCKMessage *message;

//FIXME:retain cycle
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath *indexPath;

/**
 *  显示用户头像
 */
@property (nonatomic, strong) UIImageView *avatarImageView;

/**
 *  显示用户昵称的UILabel
 */
@property (nonatomic, strong) UILabel *nickNameLabel;

/**
 *  显示用户消息主体的View,所有的消息用到的textView,imageView都会被添加到这个view中 -> LCCKContentView 自带一个CAShapeLayer的蒙版
 */
@property (nonatomic, strong) LCCKContentView *messageContentView;

/**
 *  显示消息阅读状态的UIImageView -> 主要用于VoiceMessage
 */
@property (nonatomic, strong) UIImageView *messageReadStateImageView;

/**
 *  显示消息发送状态的UIImageView -> 用于消息发送不成功时显示
 */
@property (nonatomic, strong) LCCKMessageSendStateView *messageSendStateView;

/**
 *  messageContentView的背景层
 */
@property (nonatomic, strong) UIImageView *messageContentBackgroundImageView;

@property (nonatomic, weak) id<LCCKChatMessageCellDelegate> delegate;

/**
 *  消息的类型,只读类型,会根据自己的具体实例类型进行判断
 */
@property (nonatomic, assign, readonly) AVIMMessageMediaType mediaType;

/**
 *  消息的所有者,只读类型,会根据自己的reuseIdentifier进行判断
 */
@property (nonatomic, assign, readonly) LCCKMessageOwnerType messageOwner;

/**
 *  消息群组类型,只读类型,根据reuseIdentifier判断
 */
@property (nonatomic, assign) LCCKConversationType messageChatType;

/**
 *  消息发送状态,当状态为LCCKMessageSendFail或LCCKMessageSendStateSending时,LCCKmessageSendStateImageView显示
 */
@property (nonatomic, assign) LCCKMessageSendState messageSendState;

/**
 *  消息阅读状态,当状态为LCCKMessageUnRead时,LCCKmessageReadStateImageView显示
 */
@property (nonatomic, assign) LCCKMessageReadState messageReadState;

@property (nonatomic, strong) UIColor *conversationViewMessageLeftTextColor; /**< 左侧文本消息文字颜色 */
@property (nonatomic, strong) UIColor *conversationViewMessageRightTextColor; /**< 右侧文本消息文字颜色 */

#pragma mark - Public Methods

- (void)setup;
- (void)configureCellWithData:(id)message;

@end
