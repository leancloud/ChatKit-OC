//
//  LCCKConversationViewModel.h
//  LCCKChatExample
//
//  v0.8.5 Created by ElonChan  ( https://github.com/leancloud/ChatKit-OC ) on 15/11/18.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LCCKMessage.h"
#import "LCCKConstants.h"

@class LCCKMessage;
@class LCCKConversationViewController;
@class LCCKChatMessageCell;

@protocol LCCKConversationViewModelDelegate <NSObject>

@optional
- (void)reloadAfterReceiveMessage;
- (void)messageSendStateChanged:(LCCKMessageSendState)sendState  withProgress:(CGFloat)progress forIndex:(NSUInteger)index;
- (void)messageReadStateChanged:(LCCKMessageReadState)readState withProgress:(CGFloat)progress forIndex:(NSUInteger)index;
@end

@protocol LCCKChatMessageCellDelegate;

typedef void (^LCCKSendMessageSuccessBlock)(NSString *messageUUID);
typedef void (^LCCKSendMessageSuccessFailedBlock)(NSString *messageUUID, NSError *error);

@interface LCCKConversationViewModel : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign, readonly) NSUInteger messageCount;

@property (nonatomic, weak) id<LCCKConversationViewModelDelegate> delegate;

- (instancetype)initWithParentViewController:(LCCKConversationViewController *)parentViewController;

@property (nonatomic, strong, readonly) NSMutableArray<LCCKMessage *> *dataArray;
@property (nonatomic, strong, readonly) NSMutableArray<AVIMTypedMessage *> *avimTypedMessage;

/**
 *  发送一条消息,消息已经通过addMessage添加到LCCKConversationViewModel数组中了,此方法主要为了LCCKChatServer发送消息过程
 */
- (void)sendMessage:(id)message;
- (void)sendMessage:(id)message mentionList:(NSArray<NSString *> *)mentionList;
- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage;
- (void)sendCustomMessage:(AVIMTypedMessage *)aMessage
            progressBlock:(AVProgressBlock)progressBlock
                  success:(LCCKBooleanResultBlock)success
                   failed:(LCCKBooleanResultBlock)failed;
- (void)sendLocalFeedbackTextMessge:(NSString *)localFeedbackTextMessge;
- (void)loadMessagesFirstTimeWithCallback:(LCCKIdBoolResultBlock)callback;
- (void)loadOldMessages;
- (void)getAllVisibleImagesForSelectedMessage:(LCCKMessage *)message
                             allVisibleImages:(NSArray **)allVisibleImages
                             allVisibleThumbs:(NSArray **)allVisibleThumbs
                         selectedMessageIndex:(NSNumber **)selectedMessageIndex;
- (void)resendMessageForMessageCell:(LCCKChatMessageCell *)messageCell;
- (void)modifyMessageForMessageCell:(LCCKChatMessageCell *)messageCell newMessage:(LCCKMessage *)newMessage callback:(void (^)(BOOL, NSError *))callback;
- (void)recallMessageForMessageCell:(LCCKChatMessageCell *)messageCell callback:(void (^)(BOOL, NSError *))callback;
- (void)resetBackgroundImage;
- (void)setDefaultBackgroundImage;

@end
