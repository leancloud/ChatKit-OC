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

@end

@implementation LCCKConversationViewModel

- (instancetype)initWithParentViewController:(LCCKConversationViewController *)parentConversationViewController {
    if ([super init]) {
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //设置正确的voiceMessageCell播放状态
    LCCKMessage *message = self.dataArray[indexPath.row];
    if (message.messageMediaType == LCCKMessageTypeVoice) {
        if (indexPath.row == [[LCCKAVAudioPlayer sharePlayer] index]) {
            [(LCCKChatVoiceMessageCell *)cell setVoiceMessageState:[[LCCKAVAudioPlayer sharePlayer] audioPlayerState]];
        }
    }
}

#pragma mark - LCCKChatServerDelegate

- (void)receiveMessage:(NSNotification *)notification {
    AVIMTypedMessage *message = notification.object;
    AVIMConversation *currentConversation = [LCCKConversationService sharedInstance].currentConversation;
    if ([message.conversationId isEqualToString:currentConversation.conversationId]) {
        if (currentConversation.muted == NO) {
            [[LCCKSoundManager defaultManager] playReceiveSoundIfNeed];
        }
        LCCKMessage *lcckMessage = [LCCKMessage messageWithAVIMTypedMessage:message];
        [self insertMessage:lcckMessage];
        //        [[LCCKChatManager manager] setZeroUnreadWithConversationId:self.conversation.conversationId];
        //        [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationMessageReceived object:nil];
    }
}

- (void)insertMessage:(LCCKMessage *)message {
    [self addMessage:message];
    if ([self.delegate respondsToSelector:@selector(reloadAfterReceiveMessage:)]) {
        [self.delegate reloadAfterReceiveMessage:message];
    }
}

- (void)addMessages:(NSArray<LCCKMessage *> *)messages {
    [self.dataArray addObjectsFromArray:[self messagesWithSystemMessages:messages]];
}

/*!
 * 与`-addMessages`方法的区别在于，第一次加载历史消息时需要查找最后一条消息之余还有没有消息。
 */
- (void)addMessagesFirstTime:(NSArray<LCCKMessage *> *)messages {
    [self.dataArray addObjectsFromArray:[self messagesWithLocalMessages:messages]];
    //  添加失败消息
    LCCKMessage *lastMessage = messages.lastObject;
    NSString *startDate = [lastMessage getTimestampString];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF >= %@) AND (SELF MATCHES %@)", startDate, self.timestampStringRegex];
    NSArray<LCCKMessage *> *failedLCCKMessages = [self failedMessagesWithPredicate:predicate];
    if (failedLCCKMessages.count > 0) {
        [self.dataArray addObjectsFromArray:[self messagesWithSystemMessages:failedLCCKMessages]];
    }
}

- (NSArray<LCCKMessage *> *)failedMessagesWithPredicate:(NSPredicate *)predicate {
    NSArray *allFailedMessageIdsByConversationId = [[LCCKConversationService sharedInstance] failedMessageIdsByConversationId:[LCCKConversationService sharedInstance].currentConversation.conversationId];
    //整数或小数
    //    NSString *regex = @"^[0-9]*(.)?[0-9]*$";
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
 * 该方法能让preload时动态判断插入时间戳，同时也用在第一次加载时插入时间戳。
 */
- (NSArray *)messagesWithSystemMessages:(NSArray<LCCKMessage *> *)messages {
    NSMutableArray *messageWithSystemMessages = [NSMutableArray arrayWithArray:self.dataArray];
    for (LCCKMessage *message in messages) {
        [messageWithSystemMessages addObject:message];
        BOOL shouldDisplayTimestamp = [message shouldDisplayTimestampForMessages:messageWithSystemMessages];
        if (shouldDisplayTimestamp) {
            [messageWithSystemMessages insertObject:[LCCKMessage systemMessageWithTimestamp:message.timestamp] atIndex:(messageWithSystemMessages.count - 1)];
        }
    }
    [messageWithSystemMessages removeObjectsInArray:self.dataArray];
    return [messageWithSystemMessages copy];
}

- (NSArray *)oldestFailedMessagesBeforeMessage:(LCCKMessage *)message {
    NSString *startDate = [message getTimestampString];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF <= %@) AND (SELF MATCHES %@)", startDate, self.timestampStringRegex];
    NSArray<LCCKMessage *> *failedLCCKMessages = [self failedMessagesWithPredicate:predicate];
    return failedLCCKMessages;
}

- (NSArray *)messagesWithLocalMessages:(NSArray<LCCKMessage *> *)messages {
    NSMutableArray<LCCKMessage *> *messagesWithLocalMessages = [NSMutableArray arrayWithCapacity:messages.count];
    BOOL shouldLoadMoreMessagesScrollToTop = self.parentConversationViewController.shouldLoadMoreMessagesScrollToTop;
    if (!shouldLoadMoreMessagesScrollToTop && messages.count == 0) {
        NSArray *failedMessagesByConversationId = [[LCCKConversationService sharedInstance] failedMessagesByConversationId:[LCCKConversationService sharedInstance].currentConversation.conversationId];
        messagesWithLocalMessages = [NSMutableArray arrayWithArray:failedMessagesByConversationId];
        return [self messagesWithSystemMessages:messagesWithLocalMessages];
    }
    if (!shouldLoadMoreMessagesScrollToTop) {
        LCCKMessage *message = messages[0];
        NSArray *oldestFailedMessagesBeforeMessage = [self oldestFailedMessagesBeforeMessage:message];
        NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:oldestFailedMessagesBeforeMessage];
        [mutableArray addObjectsFromArray:[messagesWithLocalMessages copy]];
        messagesWithLocalMessages = [mutableArray mutableCopy];
    }
    [messages enumerateObjectsUsingBlock:^(LCCKMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            [messagesWithLocalMessages addObject:message];
            return;
        }
        LCCKMessage *lastMessage = [messages objectAtIndex:idx - 1];
        NSString *startDate = [message getTimestampString];
        NSString *endDate = [lastMessage getTimestampString];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF >= %@) AND (SELF <= %@) AND (SELF MATCHES %@)", endDate, startDate , self.timestampStringRegex];
        NSArray<LCCKMessage *> *failedLCCKMessages = [self failedMessagesWithPredicate:predicate];
        if (failedLCCKMessages.count > 0) {
            [messagesWithLocalMessages addObjectsFromArray:failedLCCKMessages];
        }
        [messagesWithLocalMessages addObject:message];
    }];
    return [self messagesWithSystemMessages:messagesWithLocalMessages];
}

- (void)addMessage:(LCCKMessage *)message {
    [self addMessages:@[message]];
}

#pragma mark - Public Methods

- (void)sendMessage:(LCCKMessage *)message {
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
                  message.messageId = messageUUID;
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
    NSString *messageUUID =  [NSString stringWithFormat:@"%@", @(date)];
    [[LCCKConversationService sharedInstance] sendMessage:avimTypedMessage
                                             conversation:[LCCKConversationService sharedInstance].currentConversation
                                            progressBlock:progressBlock
                                                 callback:^(BOOL succeeded, NSError *error) {
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
    NSString *title = [NSString stringWithFormat:@"%@?", NSLocalizedStringFromTable(@"resend", @"LCChatKitString", @"重新发送？")];
    LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                       message:@""
                                                                preferredStyle:LCCKAlertControllerStyleAlert];
    NSString *cancelActionTitle = NSLocalizedStringFromTable(@"cancel", @"LCChatKitString", @"取消");
    LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                             handler:^(LCCKAlertAction * action) {}];
    [alert addAction:cancelAction];
    NSString *resendActionTitle = NSLocalizedStringFromTable(@"resend", @"LCChatKitString", @"重新发送");
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

    [self.parentConversationViewController.tableView reloadData];
    [self sendMessage:lcckMessage];
    [[LCCKConversationService sharedInstance] deleteFailedMessageByRecordId:lcckMessage.messageId];
}

- (void)preloadMessageToTableView:(LCCKMessage *)message {
    message.status = LCCKMessageSendStateSending;
    NSUInteger oldLastMessageCount = self.dataArray.count;
    [self addMessage:message];
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
    }];
}

- (void)queryAndCacheMessagesWithTimestamp:(int64_t)timestamp block:(AVIMArrayResultBlock)block {
    if (self.parentConversationViewController.loadingMoreMessage) {
        return;
    }
    if (self.dataArray.count == 0) {
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
    [self queryAndCacheMessagesWithTimestamp:timestamp block:^(NSArray *avimTypedMessages, NSError *error) {
        if ([self.parentConversationViewController filterAVIMError:error]) {
            NSMutableArray *lcckMessages = [[NSMutableArray lcck_messagesWithAVIMMessages:avimTypedMessages] mutableCopy];
            NSMutableArray *newMessages = [NSMutableArray arrayWithArray:avimTypedMessages];
            [newMessages addObjectsFromArray:self.avimTypedMessage];
            self.avimTypedMessage = newMessages;
            [self insertOldMessages:[self messagesWithLocalMessages:lcckMessages] completion: ^{
                self.parentConversationViewController.loadingMoreMessage = NO;
            }];
        }
    }];
}

- (void)insertOldMessages:(NSArray *)oldMessages completion:(void (^)())completion {
    NSMutableArray *messages = [NSMutableArray arrayWithArray:oldMessages];
    [messages addObjectsFromArray:self.dataArray];
    CGSize beforeContentSize = self.parentConversationViewController.tableView.contentSize;
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
    [oldMessages enumerateObjectsUsingBlock:^(LCCKMessage *message, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        [indexPaths addObject:indexPath];
    }];
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
    completion();
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

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.parentConversationViewController.isUserScrolling = NO;
}

@end
