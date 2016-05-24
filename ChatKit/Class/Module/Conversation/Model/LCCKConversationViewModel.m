//
//  LCCKConversationViewModel.m
//  LCCKChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/18.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

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
#import "AVIMEmotionMessage.h"
#import "LCCKConversationViewController.h"
#import "LCCKUserSystemService.h"
#import "LCCKSessionService.h"
#import "UIImage+LCCKExtension.h"

@interface LCCKConversationViewModel ()

@property (nonatomic, weak) LCCKConversationViewController *parentViewController;
@property (nonatomic, strong) NSMutableArray<LCCKMessage *> *dataArray;
@property (nonatomic, strong) NSMutableArray<AVIMTypedMessage *> *avimTypedMessage;

@end

@implementation LCCKConversationViewModel

- (instancetype)initWithParentViewController:(LCCKConversationViewController *)parentViewController {
    if ([super init]) {
        _dataArray = [NSMutableArray array];
        _avimTypedMessage = [NSMutableArray array];
        _parentViewController = parentViewController;
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

// 是否显示时间轴Label的回调方法
- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return NO;
    }  else {
        LCCKMessage *msg = [self.dataArray objectAtIndex:indexPath.row];
        LCCKMessage *lastMsg = [self.dataArray objectAtIndex:indexPath.row - 1];
        int interval = [msg.timestamp timeIntervalSinceDate:lastMsg.timestamp];
        if (interval > 60 * 3) {
            return YES;
        } else {
            return NO;
        }
    }
}

// 是否显示时间轴Label
- (BOOL)shouldDisplayTimestampForMessage:(LCCKMessage *)message forMessages:(NSArray *)messages {
    BOOL containsMessage= [messages containsObject:message];
    if (!containsMessage) {
        return NO;
    }
    NSUInteger index = [messages indexOfObject:message];
    if (index == 0) {
        return YES;
    }  else {
        LCCKMessage *lastMessage = [messages objectAtIndex:index - 1];
        int interval = [message.timestamp timeIntervalSinceDate:lastMessage.timestamp];
        if (interval > 60 * 3) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKMessage *message = self.dataArray[indexPath.row];
    NSString *identifier = [LCCKCellIdentifierFactory cellIdentifierForMessageConfiguration:message];
    LCCKChatMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    messageCell.tableView = self.parentViewController.tableView;
    messageCell.indexPath = indexPath;
    [messageCell configureCellWithData:message];
    messageCell.delegate = self.parentViewController;
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
        
        LCCKMessage *lcckMessage = [[self class] getLCCKMessageByMessage:message];
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

- (LCCKMessage *)timeMessage:(NSDate *)timestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    NSString *text = [dateFormatter stringFromDate:timestamp];
    LCCKMessage *timeMessage = [[LCCKMessage alloc] initWithSystemText:text];
    return timeMessage;
}

- (void)addMessages:(NSArray<LCCKMessage *> *)messages {
    [self.dataArray addObjectsFromArray:[self messagesWithSystemMessages:messages]];
}

- (NSArray *)messagesWithSystemMessages:(NSArray<LCCKMessage *> *)messages {
    NSMutableArray *messageWithSystemMessages = [NSMutableArray arrayWithArray:self.dataArray];
    for (LCCKMessage *message in messages) {
        [messageWithSystemMessages addObject:message];
        BOOL shouldDisplayTimestamp = [self shouldDisplayTimestampForMessage:message forMessages:messageWithSystemMessages];
        if (shouldDisplayTimestamp) {
            [messageWithSystemMessages insertObject:[self timeMessage:message.timestamp] atIndex:(messageWithSystemMessages.count - 1)];
        }
    }
    [messageWithSystemMessages removeObjectsInArray:self.dataArray];
    return [messageWithSystemMessages copy];
}

- (NSArray *)topMessagesWithSystemMessages:(NSArray<LCCKMessage *> *)messages {
    NSMutableArray *messageWithSystemMessages = [NSMutableArray arrayWithArray:messages];
    NSUInteger idx = 0;
    for (LCCKMessage *message in messages) {
        BOOL shouldDisplayTimestamp = [self shouldDisplayTimestampForMessage:message forMessages:messageWithSystemMessages];
        if (shouldDisplayTimestamp) {
            [messageWithSystemMessages insertObject:[self timeMessage:message.timestamp] atIndex:idx];
            idx++;
        }
        idx++;
    }
    return [messageWithSystemMessages copy];
}

- (void)addMessage:(LCCKMessage *)message {
    [self addMessages:@[message]];
}

#pragma mark - Public Methods

- (void)sendMessage:(LCCKMessage *)message {
    __weak __typeof(&*self) wself = self;
    [self.delegate messageSendStateChanged:LCCKMessageSendStateSending withProgress:0.0f forIndex:[self.dataArray indexOfObject:message]];
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
                  message.messageId = messageUUID;
                  [[LCCKConversationService sharedInstance] insertFailedLCCKMessage:message];
              }];
}

- (void)sendMessage:(LCCKMessage *)message
      progressBlock:(AVProgressBlock)progressBlock
            success:(LCCKSendMessageSuccessBlock)success
             failed:(LCCKSendMessageSuccessFailedBlock)failed {
    message.conversationId = [LCCKConversationService sharedInstance].currentConversation.conversationId;
    message.status = LCCKMessageSendStateSending;
    id<LCCKUserModelDelegate> sender = [[LCCKUserSystemService sharedInstance] fetchCurrentUser];
    message.avatorURL = sender.avatorURL;
    message.bubbleMessageType = LCCKMessageOwnerSelf;
    AVIMTypedMessage *avimTypedMessage = [LCCKConversationViewModel getAVIMTypedMessageWithMessage:message];
    [self.avimTypedMessage addObject:avimTypedMessage];
    [self preloadMessageToTableView:message];
    // if `message.messageId` is not nil, it is a failed message being resended.
    NSString *messageUUID = (message.messageId) ? message.messageId : [[NSUUID UUID] UUIDString];
    [[LCCKConversationService sharedInstance] sendMessage:avimTypedMessage
                                             conversation:[LCCKConversationService sharedInstance].currentConversation
                                            progressBlock:progressBlock
                                                 callback:^(BOOL succeeded, NSError *error) {
                                                     if (error) {
                                                         message.status = LCCKMessageStatusFailed;
                                                         !failed ?: failed(messageUUID, error);
                                                     } else {
                                                         message.status = LCCKMessageStatusSent;
                                                         !success ?: success(messageUUID);
                                                     }
                                                     //TODO:
                                                     //???:should I cache message even failed
                                                     [LCCKConversationService cacheMessages:@[avimTypedMessage] callback:nil];
                                                     dispatch_async(dispatch_get_main_queue(),^{
                                                         NSUInteger index = [self.dataArray indexOfObject:message];
                                                         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                                                         [self.parentViewController.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                     });
                                                 }];
}

- (void)resendMessageAtIndexPath:(NSIndexPath *)indexPath discardIfFailed:(BOOL)discardIfFailed {
    LCCKMessage *lcckMessage =  self.dataArray[indexPath.row];
    [self.dataArray removeObjectAtIndex:indexPath.row];
    [self.avimTypedMessage removeObjectAtIndex:indexPath.row];
    [self.parentViewController.tableView reloadData];
    [self sendMessage:lcckMessage
        progressBlock:^(NSInteger percentDone) {
            
        }
              success:^(NSString *messageUUID) {
                  [[LCCKConversationService sharedInstance] deleteFailedMessageByRecordId:messageUUID];
              } failed:^(NSString *messageUUID, NSError *error) {
                  if (discardIfFailed) {
                      // 服务器连通的情况下重发依然失败，说明消息有问题，如音频文件不存在，删掉这条消息
                      [[LCCKConversationService sharedInstance] deleteFailedMessageByRecordId:messageUUID];
                  }
              }];
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
        [self.parentViewController.tableView insertRowsAtIndexPaths:[indexPaths copy] withRowAnimation:UITableViewRowAnimationNone];
        [self.parentViewController scrollToBottomAnimated:YES];
    });
}

- (void)removeMessageAtIndex:(NSUInteger)index {
    if (index < self.dataArray.count) {
        [self.dataArray removeObjectAtIndex:index];
    }
}

- (LCCKMessage *)messageAtIndex:(NSUInteger)index {
    if (index < self.dataArray.count) {
        return self.dataArray[index];
    }
    return nil;
}

#pragma mark - Getters

- (NSUInteger)messageCount {
    return self.dataArray.count;
}

#pragma mark - modal convert

+ (NSDate *)getTimestampDate:(int64_t)timestamp {
    return [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
}

+ (LCCKMessage *)getLCCKMessageByMessage:(AVIMTypedMessage *)message {
    id<LCCKUserModelDelegate> fromUser = [[LCCKUserSystemService sharedInstance] getProfileForUserId:message.clientId error:nil];
    LCCKMessage *lcckMessage;
    NSDate *time = [self getTimestampDate:message.sendTimestamp];
    //FIXME:
    AVIMMessageMediaType mediaType = message.mediaType;
    switch (mediaType) {
        case kAVIMMessageMediaTypeText: {
            AVIMTextMessage *textMsg = (AVIMTextMessage *)message;
            lcckMessage = [[LCCKMessage alloc] initWithText:textMsg.text sender:fromUser.name timestamp:time];
            break;
        }
        case kAVIMMessageMediaTypeAudio: {
            AVIMAudioMessage *audioMsg = (AVIMAudioMessage *)message;
            NSString *duration = [NSString stringWithFormat:@"%.0f", audioMsg.duration];
            NSString *voicePath;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *pathForFile = audioMsg.file.localPath;
            if ([fileManager fileExistsAtPath:pathForFile]){
                voicePath = audioMsg.file.localPath;
            } else {
                voicePath = audioMsg.file.url;
            }
            lcckMessage = [[LCCKMessage alloc] initWithVoicePath:voicePath voiceURL:nil voiceDuration:duration sender:fromUser.name timestamp:time];
            break;
        }
            
        case kAVIMMessageMediaTypeLocation: {
            AVIMLocationMessage *locationMsg = (AVIMLocationMessage *)message;
            lcckMessage = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
                NSString *imageName = @"MessageBubble_Location";
                UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
                image;})
                                                             geolocations:locationMsg.text location:[[CLLocation alloc] initWithLatitude:locationMsg.latitude longitude:locationMsg.longitude] sender:fromUser.name timestamp:time];
            break;
        }
        case kAVIMMessageMediaTypeImage: {
            AVIMImageMessage *imageMsg = (AVIMImageMessage *)message;
            NSString *pathForFile = imageMsg.file.localPath;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *imagePath;
            if ([fileManager fileExistsAtPath:pathForFile]){
                imagePath = imageMsg.file.localPath;
            }
            lcckMessage = [[LCCKMessage alloc] initWithPhoto:nil thumbnailPhoto:nil photoPath:imagePath thumbnailURL:nil originPhotoURL:[NSURL URLWithString:imageMsg.file.url] sender:fromUser.name timestamp:time];
            break;
        }
        case kAVIMMessageMediaTypeEmotion: {
            AVIMEmotionMessage *emotionMsg = (AVIMEmotionMessage *)message;
            NSString *path = [[NSBundle mainBundle] pathForResource:emotionMsg.emotionPath ofType:@"gif"];
            lcckMessage = [[LCCKMessage alloc] initWithEmotionPath:path sender:fromUser.name timestamp:time];
            break;
        }
        case kAVIMMessageMediaTypeVideo: {
            //TODO:
            break;
        }
        default: {
            lcckMessage = [[LCCKMessage alloc] initWithText:@"未知消息" sender:fromUser.name timestamp:time];
            LCCKLog("unkonwMessage");
            break;
        }
    }
    [[LCCKConversationService sharedInstance] fecthConversationWithConversationId:message.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
        lcckMessage.messageGroupType = conversation.lcck_type;
    }];
    lcckMessage.avator = nil;
    lcckMessage.avatorURL = [fromUser avatorURL];
    
    if ([[LCCKSessionService sharedInstance].clientId isEqualToString:message.clientId]) {
        lcckMessage.bubbleMessageType = LCCKMessageOwnerSelf;
    } else {
        lcckMessage.bubbleMessageType = LCCKMessageOwnerOther;
    }
    
    NSInteger msgStatuses[4] = { AVIMMessageStatusSending, AVIMMessageStatusSent, AVIMMessageStatusDelivered, AVIMMessageStatusFailed };
    NSInteger lcckMessageStatuses[4] = { LCCKMessageSendStateSending, LCCKMessageSendStateSuccess, LCCKMessageSendStateReceived, LCCKMessageSendStateFailed };
    
    if (lcckMessage.bubbleMessageType == LCCKMessageOwnerSelf) {
        LCCKMessageSendState status = LCCKMessageSendStateReceived;
        int i;
        for (i = 0; i < 4; i++) {
            if (msgStatuses[i] == message.status) {
                status = lcckMessageStatuses[i];
                break;
            }
        }
        lcckMessage.status = status;
    } else {
        lcckMessage.status = LCCKMessageSendStateReceived;
    }
    return lcckMessage;
}

+ (NSMutableArray *)getAVIMMessages:(NSArray<LCCKMessage *> *)lcckMessages {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (LCCKMessage *message in lcckMessages) {
        AVIMTypedMessage *avimTypedMessage = [self getAVIMTypedMessageWithMessage:message];
        if (avimTypedMessage) {
            [messages addObject:avimTypedMessage];
        }
    }
    return messages;
}

+ (NSMutableArray *)getLCCKMessages:(NSArray *)avimTypedMessage {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (AVIMTypedMessage *msg in avimTypedMessage) {
        LCCKMessage *lcckMsg = [self getLCCKMessageByMessage:msg];
        if (lcckMsg) {
            [messages addObject:lcckMsg];
        }
    }
    return messages;
}

+ (AVIMTypedMessage *)getAVIMTypedMessageWithMessage:(LCCKMessage *)message {
    AVIMTypedMessage *avimTypedMessage;
    switch (message.messageMediaType) {
        case LCCKMessageTypeText: {
            avimTypedMessage = [AVIMTextMessage messageWithText:message.text attributes:nil];
            break;
        }
        case LCCKMessageTypeVideo:
        case LCCKMessageTypeImage: {
            avimTypedMessage = [AVIMImageMessage messageWithText:nil attachedFilePath:message.photoPath attributes:nil];
            break;
        }
        case LCCKMessageTypeVoice: {
            avimTypedMessage = [AVIMAudioMessage messageWithText:nil attachedFilePath:message.voicePath attributes:nil];
            break;
        }
            
        case LCCKMessageTypeEmotion:
            avimTypedMessage = [AVIMEmotionMessage messageWithEmotionPath:message.emotionName];
            break;
            
        case LCCKMessageTypeLocation: {
            avimTypedMessage = [AVIMLocationMessage messageWithText:message.geolocations
                                                           latitude:message.location.coordinate.latitude
                                                          longitude:message.location.coordinate.longitude
                                                         attributes:nil];
            break;
        case LCCKMessageTypeSystem:
        case LCCKMessageTypeUnknow:
            //TODO:
            break;
        }
    }
    avimTypedMessage.sendTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return avimTypedMessage;
}

- (void)loadMessagesWhenInitHandler:(LCCKBooleanResultBlock)handler {
    //queryMessagesFromServer
    [self queryAndCacheMessagesWithTimestamp:([[NSDate distantFuture] timeIntervalSince1970] * 1000) block:^(NSArray *avimTypedMessages, NSError *error) {
        BOOL succeed = [self.parentViewController filterAVIMError:error];
        !handler ?: handler(succeed, error);
        if (succeed) {
            // 失败消息加到末尾，因为 SDK 缓存不保存它们
            //TODO: why only when the net is ok, can the failed messages load fast
            NSMutableArray *lcckSucceedMessags = [LCCKConversationViewModel getLCCKMessages:avimTypedMessages];
            [self addMessages:lcckSucceedMessags];
            NSMutableArray *allMessages = [NSMutableArray arrayWithArray:avimTypedMessages];
            //TODO:
            //                [allMessages addObjectsFromArray:[allFailedAVIMMessages copy]];
            //                [self.dataArray addObjectsFromArray:failedMessages];
            self.avimTypedMessage = allMessages;
            dispatch_async(dispatch_get_main_queue(),^{
                [self.parentViewController.tableView reloadData];
                [self.parentViewController scrollToBottomAnimated:NO];
                self.parentViewController.loadingMoreMessage = NO;
            });
            
            if (self.avimTypedMessage.count > 0) {
                [self updateConversationAsRead];
            }
            
            // 如果连接上，则重发所有的失败消息。若夹杂在历史消息中间不好处理
            if ([LCCKSessionService sharedInstance].connect) {
                //TODO:
                //                    for (NSInteger row = self.chatViewModel.dataArray.count; row < allMessages.count; row ++) {
                //                        [self resendMessageAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] discardIfFailed:YES];
                //                    }
            }
        }
    }];
}

- (void)queryAndCacheMessagesWithTimestamp:(int64_t)timestamp block:(AVIMArrayResultBlock)block {
    if (self.parentViewController.loadingMoreMessage) {
        //TODO:if (self.parentViewController.dataSource == 0)
        return;
    }
    if (self.dataArray.count == 0) {
        timestamp = [[NSDate distantFuture] timeIntervalSince1970] * 1000;
    }
    self.parentViewController.loadingMoreMessage = YES;
    [[LCCKConversationService sharedInstance] queryTypedMessagesWithConversation:[LCCKConversationService sharedInstance].currentConversation
                                                                       timestamp:timestamp
                                                                           limit:kLCCKOnePageSize
                                                                           block:^(NSArray *avimTypedMessages, NSError *error) {
                                                                               self.parentViewController.shouldLoadMoreMessagesScrollToTop = YES;
                                                                               if (avimTypedMessages.count == 0) {
                                                                                   self.parentViewController.loadingMoreMessage = NO;
                                                                                   self.parentViewController.shouldLoadMoreMessagesScrollToTop = NO;
                                                                                   return;
                                                                               }
                                                                              
                                                                               [LCCKConversationService cacheMessages:avimTypedMessages callback:^(BOOL succeeded, NSError *error) {
                                                                                   !block ?: block(avimTypedMessages, error);
                                                                                   if (avimTypedMessages.count < kLCCKOnePageSize) {
                                                                                       self.parentViewController.shouldLoadMoreMessagesScrollToTop = NO;
                                                                                   }
                                                                               }];
                                                                           }];
}

- (void)loadOldMessages {
    AVIMTypedMessage *msg = [self.avimTypedMessage objectAtIndex:0];
    int64_t timestamp = msg.sendTimestamp;
    [self queryAndCacheMessagesWithTimestamp:timestamp block:^(NSArray *avimTypedMessages, NSError *error) {
        if ([self.parentViewController filterAVIMError:error]) {
            NSMutableArray *lcckMessages = [[[self class] getLCCKMessages:avimTypedMessages] mutableCopy];
            NSMutableArray *newMessages = [NSMutableArray arrayWithArray:avimTypedMessages];
            [newMessages addObjectsFromArray:self.avimTypedMessage];
            self.avimTypedMessage = newMessages;
            [self insertOldMessages:[self topMessagesWithSystemMessages:lcckMessages] completion: ^{
                self.parentViewController.loadingMoreMessage = NO;
            }];
        }
    }];
}

- (void)insertOldMessages:(NSArray *)oldMessages completion:(void (^)())completion{
    NSMutableArray *messages = [NSMutableArray arrayWithArray:oldMessages];
    [messages addObjectsFromArray:self.dataArray];
    CGSize beforeContentSize = self.parentViewController.tableView.contentSize;
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
    [oldMessages enumerateObjectsUsingBlock:^(LCCKMessage *message, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        [indexPaths addObject:indexPath];
    }];
    [UIView setAnimationsEnabled:NO];
    [self.parentViewController.tableView beginUpdates];
    self.dataArray = [messages mutableCopy];
    [self.parentViewController.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.parentViewController.tableView reloadData];
    [self.parentViewController.tableView endUpdates];
    CGSize afterContentSize = self.parentViewController.tableView.contentSize;
    CGPoint afterContentOffset = self.parentViewController.tableView.contentOffset;
    CGPoint newContentOffset = CGPointMake(afterContentOffset.x, afterContentOffset.y + afterContentSize.height - beforeContentSize.height);
    [self.parentViewController.tableView setContentOffset:newContentOffset animated:NO] ;
    [UIView setAnimationsEnabled:YES];
    completion();
}

#pragma mark - conversations store

- (void)updateConversationAsRead {
    AVIMConversation *conversation = [LCCKConversationService sharedInstance].currentConversation;
    if (!conversation) {
        NSAssert(conversation, @"currentConversation is nil");
        return;
    }
    [[LCCKConversationService sharedInstance] insertRecentConversation:conversation];
    [[LCCKConversationService sharedInstance] updateUnreadCountToZeroWithConversation:conversation];
    [[LCCKConversationService sharedInstance] updateMentioned:NO conversation:conversation];
    [[NSNotificationCenter defaultCenter] postNotificationName:LCCKNotificationUnreadsUpdated object:nil];
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

@end
