//
//  LCIMChatViewModel.h
//  LCIMChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/18.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LCIMMessage.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import <AVOSCloud/AVOSCloud.h>
@class LCIMMessage;
@class LCIMChatController;

@protocol LCIMChatViewModelDelegate <NSObject>

@optional
- (void)reloadAfterReceiveMessage:(LCIMMessage *)message;
- (void)messageSendStateChanged:(LCIMMessageSendState)sendState  withProgress:(CGFloat)progress forIndex:(NSUInteger)index;
- (void)messageReadStateChanged:(LCIMMessageReadState)readState withProgress:(CGFloat)progress forIndex:(NSUInteger)index;
@end

@protocol LCIMChatMessageCellDelegate;

typedef void (^LCIMSendMessageSuccessBlock)(NSString *messageUUID);
typedef void (^LCIMSendMessageSuccessFailedBlock)(NSString *messageUUID, NSError *error);

@interface LCIMChatViewModel : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign, readonly) NSUInteger messageCount;

@property (nonatomic, weak) id<LCIMChatViewModelDelegate> delegate;

- (instancetype)initWithparentViewController:(LCIMChatController *)parentViewController;

@property (nonatomic, strong, readonly) NSMutableArray<LCIMMessage *> *dataArray;
@property (nonatomic, strong, readonly) NSMutableArray<AVIMTypedMessage *> *avimTypedMessage;

/**
 *  添加一条消息到LCIMChatViewModel,并不会出发发送消息到服务器的方法
 */
- (void)addMessage:(LCIMMessage *)message;

/**
 *  发送一条消息,消息已经通过addMessage添加到LCIMChatViewModel数组中了,次方法主要为了LCIMChatServer发送消息过程
 */
- (void)sendMessage:(LCIMMessage *)message;


- (void)removeMessageAtIndex:(NSUInteger)index;

- (NSDictionary *)messageAtIndex:(NSUInteger)index;

+ (LCIMMessage *)getLCIMMessageByMsg:(AVIMTypedMessage *)message;
+ (NSMutableArray *)getAVIMMessages:(NSArray<LCIMMessage *> *)lcimMessages;
+ (AVIMTypedMessage *)getAVIMTypedMessageWithMessage:(LCIMMessage *)message;
+ (NSMutableArray *)getLCIMMessages:(NSArray<AVIMTypedMessage *> *)avimTypedMessage;
- (void)loadMessagesWhenInit;
- (void)loadOldMessages;
- (void)updateConversationAsRead;

@end
