//
//  LCCKConversationViewModel.m
//  LCCKChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/18.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//
#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif

#import "LCCKConversationViewModel.h"

#import "LCCKChatTextMessageCell.h"
#import "LCCKChatImageMessageCell.h"
#import "LCCKChatVoiceMessageCell.h"
#import "LCCKChatSystemMessageCell.h"
#import "LCCKChatLocationMessageCell.h"

#import "LCCKAVAudioPlayer.h"
#import "LCCKConstants.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKConversationService.h"
#import "LCCKSoundManager.h"

#import "UITableView+FDTemplateLayoutCell.h"
#import "LCCKCellIdentifierFactory.h"

#import "LCCKMessage.h"
#import "AVIMConversation+LCCKAddition.h"
#import <AVOSCloudIM/AVIMLocationMessage.h>
#import "LCCKConversationViewController.h"
#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"
#import "UIImage+LCCKExtension.h"
#import "AVIMTypedMessage+LCCKExtention.h"
#import "NSMutableArray+LCCKMessageExtention.h"
#import "LCCKAlertController.h"

@interface LCCKConversationViewModel ()

@property (nonatomic, strong) LCCKConversationViewController *parentConversationViewController;
@property (nonatomic, strong) NSMutableArray<LCCKMessage *> *dataArray;
@property (nonatomic, strong) NSMutableArray<AVIMTypedMessage *> *avimTypedMessage;

/*!
 * 懒加载，只在下拉刷新和第一次进入时，做消息流插入，所以在conversationViewController的生命周期里，只load一次就可以。
 */
@property (nonatomic, copy) NSArray *allFailedMessageIds;

@end

@implementation LCCKConversationViewModel

- (instancetype)initWithParentViewController:(LCCKConversationViewController *)parentConversationViewController {
    if (self = [super init]) {
        _dataArray = [NSMutableArray array];
        _avimTypedMessage = [NSMutableArray array];
        _parentConversationViewController = parentConversationViewController;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessage:) name:LCCKNotificationMessageReceived object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKMessage *message = self.dataArray[indexPath.row];
    NSString *identifier = [LCCKCellIdentifierFactory cellIdentifierForMessageConfiguration:message];
    LCCKChatMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    messageCell.tableView = self.parentConversationViewController.tableView;
    messageCell.indexPath = indexPath;
    [messageCell configureCellWithData:message];
    messageCell.delegate = self.parentConversationViewController;
    return messageCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKMessage *message = self.dataArray[indexPath.row];
    NSString *identifier = [LCCKCellIdentifierFactory cellIdentifierForMessageConfiguration:message];
    return [tableView fd_heightForCellWithIdentifier:identifier cacheByIndexPath:indexPath configuration:^(LCCKChatMessageCell *cell) {
        [cell configureCellWithData:message];
    }];
}

#pragma mark - LCCKChatServerDelegate
//FIXME:because of Memory Leak ,this method will be invoked for many times
- (void)receiveMessage:(NSNotification *)notification {
    AVIMTypedMessage *message = notification.object;
    AVIMConversation *currentConversation = [LCCKConversationService sharedInstance].currentConversation;
    if ([message.conversationId isEqualToString:currentConversation.conversationId]) {
        if (currentConversation.muted == NO) {
            [[LCCKSoundManager defaultManager] playReceiveSoundIfNeed];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            LCCKMessage *lcckMessage = [LCCKMessage messageWithAVIMTypedMessage:message];
            dispatch_async(dispatch_get_main_queue(),^{
                [self receivedOneMessage:lcckMessage];
            });
        });
    }
}

- (void)receivedOneMessage:(LCCKMessage *)message {
    [self appendMessageToTrailing:message];
    if ([self.delegate respondsToSelector:@selector(reloadAfterReceiveMessage:)]) {
        [self.delegate reloadAfterReceiveMessage:message];
    }
}

- (void)appendMessagesToTrailing:(NSArray<LCCKMessage *> *)messages {
    LCCKMessage *lastObject = (self.dataArray.count > 0) ? [self.dataArray lastObject] : nil;
    [self.dataArray addObjectsFromArray:[self messagesWithSystemMessages:messages lastMessage:lastObject]];
}

/*!
 * 与`-addMessages`方法的区别在于，第一次加载历史消息时需要查找最后一条消息之余还有没有消息。
 */
- (void)addMessagesFirstTime:(NSArray<LCCKMessage *> *)messages {
    [self.dataArray addObjectsFromArray:[self messagesWithLocalMessages:messages freshTimestamp:0]];
}

/**
 *  lazy load allFailedMessageIds
 *
 *  @return NSArray
 */
- (NSArray *)allFailedMessageIds {
    if (_allFailedMessageIds == nil) {
        NSArray *allFailedMessageIds = [[LCCKConversationService sharedInstance] failedMessageIdsByConversationId:self.parentConversationViewController.conversationId];
        _allFailedMessageIds = allFailedMessageIds;
    }
    return _allFailedMessageIds;
}

- (NSArray<LCCKMessage *> *)failedMessagesWithPredicate:(NSPredicate *)predicate {
    NSArray *allFailedMessageIdsByConversationId = self.allFailedMessageIds;
    NSArray *failedMessageIds = [allFailedMessageIdsByConversationId filteredArrayUsingPredicate:predicate];
    NSArray<LCCKMessage *> *failedLCCKMessages;
    if (failedMessageIds.count > 0) {
        failedLCCKMessages = [[LCCKConversationService sharedInstance] failedMessagesByMessageIds:failedMessageIds];
    }
    return failedLCCKMessages;
}

- (NSString *)timestampStringRegex {
    //整数或小数
    NSString *regex = @"^[0-9]*(.)?[0-9]*$";
    return regex;
}

/*!
 * @param messages 从服务端刷新下来的，夹杂着本地失败消息（但还未插入原有的旧消息self.dataArray里)。
 * 该方法能让preload时动态判断插入时间戳，同时也用在第一次加载时插入时间戳。
 */
- (NSArray *)messagesWithSystemMessages:(NSArray<LCCKMessage *> *)messages lastMessage:(LCCKMessage *)lastMessage {
    NSMutableArray *messageWithSystemMessages = lastMessage ? @[lastMessage].mutableCopy : @[].mutableCopy;
    for (LCCKMessage *message in messages) {
        [messageWithSystemMessages addObject:message];
        BOOL shouldDisplayTimestamp = [message shouldDisplayTimestampForMessages:messageWithSystemMessages];
        if (shouldDisplayTimestamp) {
            [messageWithSystemMessages insertObject:[LCCKMessage systemMessageWithTimestamp:message.timestamp] atIndex:(messageWithSystemMessages.count - 1)];
        }
    }
    if (lastMessage) {
        [messageWithSystemMessages removeObjectAtIndex:0];
    }
    return [messageWithSystemMessages copy];
}

/*!
 * 用于加载历史记录，首次进入加载以及下拉刷新加载。
 */
- (NSArray *)messagesWithSystemMessages:(NSArray<LCCKMessage *> *)messages {
    return [self messagesWithSystemMessages:messages lastMessage:nil];
}

- (NSArray *)oldestFailedMessagesBeforeMessage:(LCCKMessage *)message {
    NSString *startDate = [message getTimestampString];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF <= %@) AND (SELF MATCHES %@)", startDate, self.timestampStringRegex];
    NSArray<LCCKMessage *> *failedLCCKMessages = [self failedMessagesWithPredicate:predicate];
    return failedLCCKMessages;
}

//FIXME:连续发1到20，如果第11个数是失败消息，那么11无法显示。
/*!
 * freshTimestamp 下拉刷新的时间戳, 为0表示从当前时间开始查询。
 ＊ @param messages 服务端返回到消息，如果一次拉去的是10条，那么这个数组将是10条，或少于10条。
 */
- (NSArray *)messagesWithLocalMessages:(NSArray<LCCKMessage *> *)messages freshTimestamp:(int64_t)timestamp {
    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @(timestamp));
    NSMutableArray<LCCKMessage *> *messagesWithLocalMessages = [NSMutableArray arrayWithCapacity:messages.count];
    BOOL shouldLoadMoreMessagesScrollToTop = self.parentConversationViewController.shouldLoadMoreMessagesScrollToTop;
    //情况一：只有失败消息的情况，直接返回数据库所有失败消息
    if (!shouldLoadMoreMessagesScrollToTop && messages.count == 0) {
        NSArray *failedMessagesByConversationId = [[LCCKConversationService sharedInstance] failedMessagesByConversationId:[LCCKConversationService sharedInstance].currentConversation.conversationId];
        messagesWithLocalMessages = [NSMutableArray arrayWithArray:failedMessagesByConversationId];
        return [self messagesWithSystemMessages:messagesWithLocalMessages];
    }
    //情况二：正常情况，服务端有消息返回
    
    //服务端的历史纪录已经加载完成，将比服务端最旧的一条消息还旧的失败消息拼接到顶端。
    if (!shouldLoadMoreMessagesScrollToTop) {
        LCCKMessage *message = messages[0];
        NSArray *oldestFailedMessagesBeforeMessage = [self oldestFailedMessagesBeforeMessage:message];
        NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:oldestFailedMessagesBeforeMessage];
        [mutableArray addObjectsFromArray:[messagesWithLocalMessages copy]];
        messagesWithLocalMessages = [mutableArray mutableCopy];
    }
    
    /*!
     *
     
    index         | 参数         |     参数       |     屏幕位置
     -------------|-------------|----------------|-------------
     0            |             ｜               |      顶部
     1            |   fromDate  |   lastMessage  |      上
     2            |     --      |  failedMessage |      中
     3            |    toDate   |     message    |      下
     ...          |             |                |
fromTimestamp     |             |                |
     
     */
    
    [messages enumerateObjectsUsingBlock:^(LCCKMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        int64_t fromDate;
        int64_t toDate;
        if (idx == 0) {
            [messagesWithLocalMessages addObject:message];
            return;
        }
        LCCKMessage *lastMessage = [messages objectAtIndex:idx - 1];
        fromDate = [lastMessage timestamp];
        toDate = [message timestamp];
        [self appendFailedMessagesToMessagesWithLocalMessages:messagesWithLocalMessages fromDate:fromDate toDate:toDate];
        [messagesWithLocalMessages addObject:message];
        BOOL isLastObject = [message isEqual:[messages lastObject]];
        if (isLastObject) {
            fromDate = message.timestamp;
            toDate = timestamp;
            if (timestamp == 0) {
                toDate = [[NSDate distantFuture] timeIntervalSince1970] * 1000;
            }
            [self appendFailedMessagesToMessagesWithLocalMessages:messagesWithLocalMessages fromDate:fromDate toDate:toDate];
        }
    }];
    return [self messagesWithSystemMessages:messagesWithLocalMessages];
}

- (void)appendFailedMessagesToMessagesWithLocalMessages:(NSMutableArray *)messagesWithLocalMessages fromDate:(int64_t)fromDate toDate:(int64_t)toDate {
    NSArray<LCCKMessage *> *failedLCCKMessages = [self failedLCCKMessagesWithFromDate:fromDate toDate:toDate];
    if (failedLCCKMessages.count > 0) {
        [messagesWithLocalMessages addObjectsFromArray:failedLCCKMessages];
    }
}

- (NSArray *)failedLCCKMessagesWithFromDate:(int64_t)fromDate toDate:(int64_t)toDate {
    NSString *fromDateString = [NSString stringWithFormat:@"%@", @(fromDate)];
    NSString *toDateString = [NSString stringWithFormat:@"%@", @(toDate)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF >= %@) AND (SELF <= %@) AND (SELF MATCHES %@)", fromDateString, toDateString , self.timestampStringRegex];
    NSArray<LCCKMessage *> *failedLCCKMessages = [self failedMessagesWithPredicate:predicate];
    return failedLCCKMessages;
}

- (void)appendMessageToTrailing:(LCCKMessage *)message {
    [self appendMessagesToTrailing:@[message]];
}

#pragma mark - Public Methods

- (void)sendMessage:(LCCKMessage *)message {
    self.parentConversationViewController.allowScrollToBottom = YES;
    __weak __typeof(&*self) wself = self;
    [self sendMessage:message
        progressBlock:^(NSInteger percentDone) {
            [self.delegate messageSendStateChanged:LCCKMessageSendStateSending withProgress:percentDone/100.f forIndex:[self.dataArray indexOfObject:message]];
        }
              success:^(NSString *messageUUID) {
                  message.status = LCCKMessageSendStateSuccess;
                  [[LCCKSoundManager defaultManager] playSendSoundIfNeed];
                  [self.delegate messageSendStateChanged:LCCKMessageSendStateSuccess withProgress:1.0f forIndex:[self.dataArray indexOfObject:message]];
              } failed:^(NSString *messageUUID, NSError *error) {
                  __strong __typeof(wself)self = wself;
                  message.status = LCCKMessageSendStateFailed;
                  [self.delegate messageSendStateChanged:LCCKMessageSendStateFailed withProgress:0.0f forIndex:[self.dataArray indexOfObject:message]];
                  [[LCCKConversationService sharedInstance] insertFailedLCCKMessage:message];
              }];
}

- (void)sendMessage:(LCCKMessage *)message
      progressBlock:(AVProgressBlock)progressBlock
            success:(LCCKSendMessageSuccessBlock)success
             failed:(LCCKSendMessageSuccessFailedBlock)failed {
    [self.delegate messageSendStateChanged:LCCKMessageSendStateSending withProgress:0.0f forIndex:[self.dataArray indexOfObject:message]];
    message.conversationId = [LCCKConversationService sharedInstance].currentConversationId ?: [LCCKConversationService sharedInstance].currentConversation.conversationId;
    NSAssert(message.conversationId, @"currentConversationId is nil");
    message.status = LCCKMessageSendStateSending;
    id<LCCKUserDelegate> sender = [[LCCKUserSystemService sharedInstance] fetchCurrentUser];
    message.user = sender;
    message.bubbleMessageType = LCCKMessageOwnerSelf;
    AVIMTypedMessage *avimTypedMessage = [AVIMTypedMessage lcck_messageWithLCCKMessage:message];
    [self.avimTypedMessage addObject:avimTypedMessage];
    [self preloadMessageToTableView:message];
    NSTimeInterval date = [[NSDate date] timeIntervalSince1970] * 1000;
    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @(date));
    NSString *messageUUID =  [NSString stringWithFormat:@"%@", @(date)];
    [[LCCKConversationService sharedInstance] sendMessage:avimTypedMessage
                                             conversation:[LCCKConversationService sharedInstance].currentConversation
                                            progressBlock:progressBlock
                                                 callback:^(BOOL succeeded, NSError *error) {
                                                     message.localMessageId = messageUUID;
                                                     if (error) {
                                                         !failed ?: failed(messageUUID, error);
                                                     } else {
                                                         !success ?: success(messageUUID);
                                                     }
                                                     // cache file type messages even failed
                                                     [LCCKConversationService cacheFileTypeMessages:@[avimTypedMessage] callback:nil];
                                                 }];
}

- (void)resendMessageForMessageCell:(LCCKChatMessageCell *)messageCell {
    NSString *title = [NSString stringWithFormat:@"%@?", LCCKLocalizedStrings(@"resend")];
    LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                       message:@""
                                                                preferredStyle:LCCKAlertControllerStyleAlert];
    NSString *cancelActionTitle = LCCKLocalizedStrings(@"cancel");
    LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                             handler:^(LCCKAlertAction * action) {}];
    [alert addAction:cancelAction];
    NSString *resendActionTitle = LCCKLocalizedStrings(@"resend");
    LCCKAlertAction* resendAction = [LCCKAlertAction actionWithTitle:resendActionTitle style:LCCKAlertActionStyleDefault
                                                             handler:^(LCCKAlertAction * action) {
                                                                 [self resendMessageAtIndexPath:messageCell.indexPath];
                                                             }];
    [alert addAction:resendAction];
    [alert showWithSender:nil controller:self.parentConversationViewController animated:YES completion:NULL];
}

- (void)resendMessageAtIndexPath:(NSIndexPath *)indexPath {
    LCCKMessage *lcckMessage =  self.dataArray[indexPath.row];
    NSUInteger row = indexPath.row;
    @try {
        LCCKMessage *message = self.dataArray[row - 1];
        if (message.messageMediaType == LCCKMessageTypeSystem) {
            [self.dataArray lcck_removeMessageAtIndex:row - 1];
            [self.avimTypedMessage lcck_removeMessageAtIndex:row - 1];
            row -= 1;
        }
    } @catch (NSException *exception) {}
    
    [self.dataArray lcck_removeMessageAtIndex:row];
    [self.avimTypedMessage lcck_removeMessageAtIndex:row];
    NSString *oldFailedMessageId = lcckMessage.localMessageId;
    [self.parentConversationViewController.tableView reloadData];
    self.parentConversationViewController.allowScrollToBottom = YES;
    [self sendMessage:lcckMessage];
    [[LCCKConversationService sharedInstance] deleteFailedMessageByRecordId:oldFailedMessageId];
}

- (void)preloadMessageToTableView:(LCCKMessage *)message {
    message.status = LCCKMessageSendStateSending;
    NSUInteger oldLastMessageCount = self.dataArray.count;
    [self appendMessageToTrailing:message];
    NSUInteger newLastMessageCout = self.dataArray.count;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataArray.count - 1 inSection:0];
    [self.delegate messageSendStateChanged:LCCKMessageSendStateSending withProgress:0.0f forIndex:indexPath.row];
    NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:indexPath];
    NSUInteger additionItemsCount = newLastMessageCout - oldLastMessageCount;
    if (additionItemsCount > 1) {
        for (NSUInteger index = 2; index <= additionItemsCount; index++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newLastMessageCout - index inSection:0];
            [indexPaths addObject:indexPath];
        }
    }
    dispatch_async(dispatch_get_main_queue(),^{
        [self.parentConversationViewController.tableView insertRowsAtIndexPaths:[indexPaths copy] withRowAnimation:UITableViewRowAnimationNone];
        [self.parentConversationViewController scrollToBottomAnimated:YES];
    });
}

#pragma mark - Getters

- (NSUInteger)messageCount {
    return self.dataArray.count;
}

- (void)loadMessagesFirstTimeWithHandler:(LCCKBooleanResultBlock)handler {
    //为确保消息的连续性，首次加载聊天记录应始终queryMessagesFromServer，只需禁用message缓存即可达到该效果。
    AVIMConversation *conversation = [LCCKConversationService sharedInstance].currentConversation;
    BOOL socketOpened = [LCCKSessionService sharedInstance].connect;
    //必须在socketOpened时禁用，否则，`queryAndCacheMessagesWithTimestamp` 会在socket not opened 状态时返回nil。
    if (socketOpened) {
        conversation.imClient.messageQueryCacheEnabled = NO;
    }
    [self queryAndCacheMessagesWithTimestamp:([[NSDate distantFuture] timeIntervalSince1970] * 1000) block:^(NSArray *avimTypedMessages, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            conversation.imClient.messageQueryCacheEnabled = YES;
            BOOL succeed = [self.parentConversationViewController filterAVIMError:error];
            if (succeed) {
                NSMutableArray *lcckSucceedMessags = [NSMutableArray lcck_messagesWithAVIMMessages:avimTypedMessages];
                [self addMessagesFirstTime:lcckSucceedMessags];
                NSMutableArray *allMessages = [NSMutableArray arrayWithArray:avimTypedMessages];
                self.avimTypedMessage = allMessages;
                dispatch_async(dispatch_get_main_queue(),^{
                    [self.parentConversationViewController.tableView reloadData];
                    [self.parentConversationViewController scrollToBottomAnimated:NO];
                    self.parentConversationViewController.loadingMoreMessage = NO;
                });
                
                if (self.avimTypedMessage.count > 0) {
                    [[LCCKConversationService sharedInstance] updateConversationAsRead];
                }
            } else {
                self.parentConversationViewController.loadingMoreMessage = NO;
            }
            !handler ?: handler(succeed, error);
        });
    }];
}

- (void)queryAndCacheMessagesWithTimestamp:(int64_t)timestamp block:(AVIMArrayResultBlock)block {
    if (self.parentConversationViewController.loadingMoreMessage) {
        return;
    }
    if (self.dataArray.count == 0 || !timestamp) {
        timestamp = [[NSDate distantFuture] timeIntervalSince1970] * 1000;
    }
    self.parentConversationViewController.loadingMoreMessage = YES;
    [[LCCKConversationService sharedInstance] queryTypedMessagesWithConversation:[LCCKConversationService sharedInstance].currentConversation
                                                                       timestamp:timestamp
                                                                           limit:kLCCKOnePageSize
                                                                           block:^(NSArray *avimTypedMessages, NSError *error) {
                                                                               self.parentConversationViewController.shouldLoadMoreMessagesScrollToTop = YES;
                                                                               if (avimTypedMessages.count == 0) {
                                                                                   self.parentConversationViewController.loadingMoreMessage = NO;
                                                                                   self.parentConversationViewController.shouldLoadMoreMessagesScrollToTop = NO;
                                                                                   !block ?: block(avimTypedMessages, error);
                                                                                   return;
                                                                               }
                                                                               [LCCKConversationService cacheFileTypeMessages:avimTypedMessages callback:^(BOOL succeeded, NSError *error) {
                                                                                   if (avimTypedMessages.count < kLCCKOnePageSize) {
                                                                                       self.parentConversationViewController.shouldLoadMoreMessagesScrollToTop = NO;
                                                                                   }
                                                                                   !block ?: block(avimTypedMessages, error);
                                                                               }];
                                                                           }];
}

- (void)loadOldMessages {
    AVIMTypedMessage *msg = [self.avimTypedMessage lcck_messageAtIndex:0];
    int64_t timestamp = msg.sendTimestamp;
    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @(timestamp));
    [self queryAndCacheMessagesWithTimestamp:timestamp block:^(NSArray *avimTypedMessages, NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if ([self.parentConversationViewController filterAVIMError:error]) {
                NSMutableArray *lcckMessages = [[NSMutableArray lcck_messagesWithAVIMMessages:avimTypedMessages] mutableCopy];
                NSMutableArray *newMessages = [NSMutableArray arrayWithArray:avimTypedMessages];
                [newMessages addObjectsFromArray:self.avimTypedMessage];
                self.avimTypedMessage = newMessages;
                [self insertOldMessages:[self messagesWithLocalMessages:lcckMessages freshTimestamp:timestamp] completion: ^{
                    self.parentConversationViewController.loadingMoreMessage = NO;
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(),^{
                    self.parentConversationViewController.loadingMoreMessage = NO;
                });
            }
        });
    }];
}

- (void)insertOldMessages:(NSArray *)oldMessages completion:(void (^)())completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableArray *messages = [NSMutableArray arrayWithArray:oldMessages];
        [messages addObjectsFromArray:self.dataArray];
        CGSize beforeContentSize = self.parentConversationViewController.tableView.contentSize;
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
        [oldMessages enumerateObjectsUsingBlock:^(LCCKMessage *message, NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [indexPaths addObject:indexPath];
        }];
        dispatch_async(dispatch_get_main_queue(),^{
            [UIView setAnimationsEnabled:NO];
            [self.parentConversationViewController.tableView beginUpdates];
            self.dataArray = [messages mutableCopy];
            [self.parentConversationViewController.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [self.parentConversationViewController.tableView reloadData];
            [self.parentConversationViewController.tableView endUpdates];
            CGSize afterContentSize = self.parentConversationViewController.tableView.contentSize;
            CGPoint afterContentOffset = self.parentConversationViewController.tableView.contentOffset;
            CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - beforeContentSize.height);
            [self.parentConversationViewController.tableView setContentOffset:newContentOffset animated:NO] ;
            [UIView setAnimationsEnabled:YES];
            !completion ?: completion();
        });
    });
}

- (void)getAllVisibleImagesForSelectedMessage:(LCCKMessage *)message
                             allVisibleImages:(NSArray **)allVisibleImages
                             allVisibleThumbs:(NSArray **)allVisibleThumbs
                         selectedMessageIndex:(NSNumber **)selectedMessageIndex {
    NSMutableArray *allVisibleImages_ = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableArray *allVisibleThumbs_ = [[NSMutableArray alloc] initWithCapacity:0];
    NSUInteger idx = 0;
    for (LCCKMessage *message_ in self.dataArray) {
        BOOL isImageType = (message_.messageMediaType == LCCKMessageTypeImage || message_.photo || message_.originPhotoURL);
        if (isImageType) {
            UIImage *placeholderImage = ({
                NSString *imageName = @"Placeholder_Accept_Defeat";
                UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[self class]];
                image;});
            //大图设置
            UIImage *image = message_.photo;
            if (image) {
                [allVisibleImages_ addObject:image];
            } else if (message_.originPhotoURL) {
                [allVisibleImages_ addObject:message_.originPhotoURL];
            } else {
                [allVisibleImages_ addObject:placeholderImage];
            }
            //缩略图设置
            UIImage *thumb = message_.thumbnailPhoto;
            if (thumb) {
                [allVisibleThumbs_ addObject:thumb];
            } else if (message_.thumbnailURL) {
                [allVisibleThumbs_ addObject:message_.thumbnailURL];
            } else {
                [allVisibleThumbs_ addObject:placeholderImage];
            }
            if ((message == message_) && (*selectedMessageIndex == nil)){
                *selectedMessageIndex = @(idx);
            }
            idx++;
        }
    }
    if (*allVisibleImages == nil) {
        *allVisibleImages = [allVisibleImages_ copy];
    }
    if (*allVisibleThumbs == nil) {
        *allVisibleThumbs = [allVisibleThumbs_ copy];
    }
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.parentConversationViewController.isUserScrolling = YES;
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (menu.isMenuVisible) {
        [menu setMenuVisible:NO animated:YES];
    }
    [self.parentConversationViewController.chatBar endInputing];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.parentConversationViewController.isUserScrolling = NO;
    BOOL allowScrollToBottom = self.parentConversationViewController.allowScrollToBottom;
    CGFloat frameBottomToContentBottom = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y;
    //200：差不多是两行
    if (frameBottomToContentBottom < 200) {
        allowScrollToBottom = YES;
    } else {
        allowScrollToBottom = NO;
    }
    self.parentConversationViewController.allowScrollToBottom = allowScrollToBottom;
}

@end
