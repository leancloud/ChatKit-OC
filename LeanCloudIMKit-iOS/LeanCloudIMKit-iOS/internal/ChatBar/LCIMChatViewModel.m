//
//  LCIMChatViewModel.m
//  LCIMChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/18.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMChatViewModel.h"

#import "LCIMChatTextMessageCell.h"
#import "LCIMChatImageMessageCell.h"
#import "LCIMChatVoiceMessageCell.h"
#import "LCIMChatSystemMessageCell.h"
#import "LCIMChatLocationMessageCell.h"

#import "LCIMAVAudioPlayer.h"
//#import "LCIMChatServerExample.h"
#import "LCIMConstants.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMMessageStateManager.h"
#import "LCIMConversationService.h"
#import "LCIMSoundManager.h"

#import "UITableView+FDTemplateLayoutCell.h"
#import "LCIMCellIdentifierFactory.h"

#import "LCIMMessage.h"
#import "LCIMEmotionUtils.h"
#import "AVIMConversation+LCIMAddition.h"
#import "AVIMLocationMessage.h"
#import "AVIMEmotionMessage.h"
#import "LCIMEmotionUtils.h"
#import "LCIMChatController.h"
#import "NSDate+DateTools.h"

@interface LCIMChatViewModel ()

@property (nonatomic, weak) LCIMChatController *parentViewController;
@property (nonatomic, strong) NSMutableArray<LCIMMessage *> *dataArray;
@property (nonatomic, strong) NSMutableArray<AVIMTypedMessage *> *avimTypedMessage;

@end

@implementation LCIMChatViewModel

- (instancetype)initWithparentViewController:(LCIMChatController *)parentViewController {
    if ([super init]) {
        _dataArray = [NSMutableArray array];
        _avimTypedMessage = [NSMutableArray array];
        _parentViewController = parentViewController;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessage:) name:LCIMNotificationMessageReceived object:nil];
    }
    return self;
}

- (void)dealloc {
    [[LCIMMessageStateManager shareManager] cleanState];
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
        LCIMMessage *msg = [self.dataArray objectAtIndex:indexPath.row];
        LCIMMessage *lastMsg = [self.dataArray objectAtIndex:indexPath.row - 1];
        int interval = [msg.timestamp timeIntervalSinceDate:lastMsg.timestamp];
        if (interval > 60 * 3) {
            return YES;
        } else {
            return NO;
        }
    }
}

// 是否显示时间轴Label
- (BOOL)shouldDisplayTimestampForMessage:(LCIMMessage *)message forMessages:(NSArray *)messages {
    BOOL containsMessage= [messages containsObject:message];
    if (!containsMessage) {
        return NO;
    }
    NSUInteger index = [messages indexOfObject:message];
    if (index == 0) {
        return YES;
    }  else {
        LCIMMessage *lastMessage = [messages objectAtIndex:index - 1];
        int interval = [message.timestamp timeIntervalSinceDate:lastMessage.timestamp];
        if (interval > 60 * 3) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCIMMessage *message = self.dataArray[indexPath.row];
    NSString *identifier = [LCIMCellIdentifierFactory cellIdentifierForMessageConfiguration:message];
    LCIMChatMessageCell *messageCell = [tableView dequeueReusableCellWithIdentifier:identifier];
    [messageCell configureCellWithData:message];
    messageCell.messageReadState = [[LCIMMessageStateManager shareManager] messageReadStateForIndex:indexPath.row];
    messageCell.messageSendState = [[LCIMMessageStateManager shareManager] messageSendStateForIndex:indexPath.row];
    messageCell.delegate = self.parentViewController;
    return messageCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCIMMessage *message = self.dataArray[indexPath.row];
    NSString *identifier = [LCIMCellIdentifierFactory cellIdentifierForMessageConfiguration:message];
    return [tableView fd_heightForCellWithIdentifier:identifier cacheByIndexPath:indexPath configuration:^(LCIMChatMessageCell *cell) {
        [cell configureCellWithData:message];
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //设置正确的voiceMessageCell播放状态
    LCIMMessage *message = self.dataArray[indexPath.row];
    if (message.messageMediaType == LCIMMessageTypeVoice) {
        if (indexPath.row == [[LCIMAVAudioPlayer sharePlayer] index]) {
            [(LCIMChatVoiceMessageCell *)cell setVoiceMessageState:[[LCIMAVAudioPlayer sharePlayer] audioPlayerState]];
        }
    }
}

#pragma mark - LCIMChatServerDelegate

- (void)receiveMessage:(NSNotification *)notification {
    AVIMTypedMessage *message = notification.object;
    AVIMConversation *currentConversation = [LCIMConversationService sharedInstance].currentConversation;
    if ([message.conversationId isEqualToString:currentConversation.conversationId]) {
        if (currentConversation.muted == NO) {
            [[LCIMSoundManager defaultManager] playReceiveSoundIfNeed];
        }
        
        LCIMMessage *lcimMessage = [[self class] getLCIMMessageByMessage:message];
        [self insertMessage:lcimMessage];
        //        [[LCIMChatManager manager] setZeroUnreadWithConversationId:self.conversation.conversationId];
        //        [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationMessageReceived object:nil];
    }
}

- (void)insertMessage:(LCIMMessage *)message {
    [self addMessage:message];
    if ([self.delegate respondsToSelector:@selector(reloadAfterReceiveMessage:)]) {
        [self.delegate reloadAfterReceiveMessage:message];
    }
}

- (LCIMMessage *)timeMessage:(NSDate *)timestamp {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd HH:mm"];
    NSString *text = [dateFormatter stringFromDate:timestamp];
    LCIMMessage *timeMessage = [[LCIMMessage alloc] initWithSystemText:text];
    return timeMessage;
}

- (void)addMessages:(NSArray<LCIMMessage *> *)messages {
    [self.dataArray addObjectsFromArray:[self messagesWithSystemMessages:messages]];
}

- (NSArray *)messagesWithSystemMessages:(NSArray<LCIMMessage *> *)messages {
    NSMutableArray *messageWithSystemMessages = [NSMutableArray arrayWithArray:self.dataArray];
    for (LCIMMessage *message in messages) {
        [messageWithSystemMessages addObject:message];
        BOOL shouldDisplayTimestamp = [self shouldDisplayTimestampForMessage:message forMessages:messageWithSystemMessages];
        if (shouldDisplayTimestamp) {
            [messageWithSystemMessages insertObject:[self timeMessage:message.timestamp] atIndex:(messageWithSystemMessages.count - 1)];
        }
    }
    [messageWithSystemMessages removeObjectsInArray:self.dataArray];
    return [messageWithSystemMessages copy];
}

- (NSArray *)topMessagesWithSystemMessages:(NSArray<LCIMMessage *> *)messages {
    NSMutableArray *messageWithSystemMessages = [NSMutableArray arrayWithArray:messages];
    NSUInteger idx = 0;
    for (LCIMMessage *message in messages) {
        BOOL shouldDisplayTimestamp = [self shouldDisplayTimestampForMessage:message forMessages:messageWithSystemMessages];
        if (shouldDisplayTimestamp) {
            [messageWithSystemMessages insertObject:[self timeMessage:message.timestamp] atIndex:idx];
            idx++;
        }
        idx++;
    }
    return [messageWithSystemMessages copy];
}

- (void)addMessage:(LCIMMessage *)message {
    [self addMessages:@[message]];
}

#pragma mark - Public Methods

- (void)sendMessage:(LCIMMessage *)message {
    __weak __typeof(&*self) wself = self;
    [[LCIMMessageStateManager shareManager] setMessageSendState:LCIMMessageSendStateSending forIndex:[self.dataArray indexOfObject:message]];
    [self.delegate messageSendStateChanged:LCIMMessageSendStateSending withProgress:0.0f forIndex:[self.dataArray indexOfObject:message]];
    [self sendMessage:message success:^(NSString *messageUUID) {
        __strong __typeof(wself)self = wself;
        [[LCIMMessageStateManager shareManager] setMessageSendState:LCIMMessageSendStateSuccess forIndex:[self.dataArray indexOfObject:message]];
        [self.delegate messageSendStateChanged:LCIMMessageSendStateSuccess withProgress:1.0f forIndex:[self.dataArray indexOfObject:message]];
        [[LCIMSoundManager defaultManager] playSendSoundIfNeed];
    } failed:^(NSString *messageUUID, NSError *error) {
        __strong __typeof(wself)self = wself;
        [[LCIMMessageStateManager shareManager] setMessageSendState:LCIMMessageSendStateFailed forIndex:[self.dataArray indexOfObject:message]];
        [self.delegate messageSendStateChanged:LCIMMessageSendStateFailed withProgress:1.0f forIndex:[self.dataArray indexOfObject:message]];
        message.messageId = messageUUID;
        [[LCIMConversationService sharedInstance] insertFailedLCIMMessage:message];
    }];
}

- (void)sendMessage:(LCIMMessage *)message success:(LCIMSendMessageSuccessBlock)success failed:(LCIMSendMessageSuccessFailedBlock)failed {
    message.conversationId = [LCIMConversationService sharedInstance].currentConversation.conversationId;
    message.status = LCIMMessageSendStateSending;
    message.bubbleMessageType = LCIMMessageOwnerSelf;
    AVIMTypedMessage *avimTypedMessage = [LCIMChatViewModel getAVIMTypedMessageWithMessage:message];
    [self.avimTypedMessage addObject:avimTypedMessage];
    [self preloadMessageToTableView:message];
    
    // if `message.messageId` is not nil, it is a failed message being resended.
    NSString *messageUUID = (message.messageId) ? message.messageId : [[NSUUID UUID] UUIDString];
    [[LCIMConversationService sharedInstance] sendMessage:avimTypedMessage conversation:[LCIMConversationService sharedInstance].currentConversation callback:^(BOOL succeeded, NSError *error) {
        if (error) {
            message.status = LCIMMessageStatusFailed;
            !failed ?: failed(messageUUID, error);
        } else {
            message.status = LCIMMessageStatusSent;
            !success ?: success(messageUUID);
        }
        //TODO:
        //???:should I cache message even failed
        [LCIMConversationService cacheMessages:@[avimTypedMessage] callback:nil];
        dispatch_async(dispatch_get_main_queue(),^{
            NSUInteger index = [self.dataArray indexOfObject:message];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.parentViewController.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }];
}

- (void)resendMessageAtIndexPath:(NSIndexPath *)indexPath discardIfFailed:(BOOL)discardIfFailed {
    LCIMMessage *lcimMessage =  self.dataArray[indexPath.row];
    [self.dataArray removeObjectAtIndex:indexPath.row];
    [self.avimTypedMessage removeObjectAtIndex:indexPath.row];
    [self.parentViewController.tableView reloadData];
    [self sendMessage:lcimMessage success:^(NSString *messageUUID) {
        [[LCIMConversationService sharedInstance] deleteFailedMessageByRecordId:messageUUID];
    } failed:^(NSString *messageUUID, NSError *error) {
        if (discardIfFailed) {
            // 服务器连通的情况下重发依然失败，说明消息有问题，如音频文件不存在，删掉这条消息
            [[LCIMConversationService sharedInstance] deleteFailedMessageByRecordId:messageUUID];
        }
    }];
}

- (void)preloadMessageToTableView:(LCIMMessage *)message {
    [self addMessage:message];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataArray.count - 1 inSection:0];
    dispatch_async(dispatch_get_main_queue(),^{
        [self.parentViewController.tableView reloadData];
//        [self.parentViewController.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.parentViewController scrollToBottomAnimated:YES];
    });
}

- (void)removeMessageAtIndex:(NSUInteger)index {
    if (index < self.dataArray.count) {
        [self.dataArray removeObjectAtIndex:index];
    }
}

- (LCIMMessage *)messageAtIndex:(NSUInteger)index {
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

+ (LCIMMessage *)getLCIMMessageByMessage:(AVIMTypedMessage *)message {
    id<LCIMUserModelDelegate> fromUser = [[LCIMUserSystemService sharedInstance] getProfileForUserId:message.clientId error:nil];
    LCIMMessage *lcimMessage;
    NSDate *time = [self getTimestampDate:message.sendTimestamp];
    //FIXME:
    if (message.mediaType == kAVIMMessageMediaTypeText) {
        AVIMTextMessage *textMsg = (AVIMTextMessage *)message;
        lcimMessage = [[LCIMMessage alloc] initWithText:[LCIMEmotionUtils emojiStringFromString:textMsg.text] sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeAudio) {
        AVIMAudioMessage *audioMsg = (AVIMAudioMessage *)message;
        NSString *duration = [NSString stringWithFormat:@"%.0f", audioMsg.duration];
        lcimMessage = [[LCIMMessage alloc] initWithVoicePath:audioMsg.file.localPath voiceURL:nil voiceDuration:duration sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeLocation) {
        AVIMLocationMessage *locationMsg = (AVIMLocationMessage *)message;
        lcimMessage = [[LCIMMessage alloc] initWithLocalPositionPhoto:({
            NSString *imageName = @"MessageBubble_Location";
            NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"MessageBubble.bundle/%@", imageName];
            UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
            image;})
                                                         geolocations:locationMsg.text location:[[CLLocation alloc] initWithLatitude:locationMsg.latitude longitude:locationMsg.longitude] sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeImage) {
        AVIMImageMessage *imageMsg = (AVIMImageMessage *)message;
        lcimMessage = [[LCIMMessage alloc] initWithPhoto:nil photoPath:nil thumbnailURL:nil originPhotoURL:[NSURL URLWithString:imageMsg.file.url] sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeEmotion) {
        AVIMEmotionMessage *emotionMsg = (AVIMEmotionMessage *)message;
        NSString *path = [[NSBundle mainBundle] pathForResource:emotionMsg.emotionPath ofType:@"gif"];
        lcimMessage = [[LCIMMessage alloc] initWithEmotionPath:path sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
        AVIMVideoMessage *videoMsg = (AVIMVideoMessage *)message;
        NSString *path = [[LCIMSettingService sharedInstance] videoPathOfMessage:videoMsg];
        lcimMessage = [[LCIMMessage alloc] initWithVideoConverPhoto:[XHMessageVideoConverPhotoFactory videoConverPhotoWithVideoPath:path] videoPath:path videoURL:nil sender:fromUser.name timestamp:time];
    } else {
        lcimMessage = [[LCIMMessage alloc] initWithText:@"未知消息" sender:fromUser.name timestamp:time];
        DLog("unkonwMessage");
    }
    [[LCIMConversationService sharedInstance] fecthConversationWithConversationId:message.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
        lcimMessage.messageGroupType = conversation.lcim_type;
    }];
    lcimMessage.avator = nil;
    lcimMessage.avatorURL = [fromUser avatorURL];
    
    if ([[LCIMSessionService sharedInstance].clientId isEqualToString:message.clientId]) {
        lcimMessage.bubbleMessageType = LCIMMessageOwnerSelf;
    } else {
        lcimMessage.bubbleMessageType = LCIMMessageOwnerOther;
    }
    
    NSInteger msgStatuses[4] = { AVIMMessageStatusSending, AVIMMessageStatusSent, AVIMMessageStatusDelivered, AVIMMessageStatusFailed };
    NSInteger lcimMessageStatuses[4] = { LCIMMessageSendStateSending, LCIMMessageSendStateSuccess, LCIMMessageSendStateReceived, LCIMMessageSendStateFailed };
    
    if (lcimMessage.bubbleMessageType == LCIMMessageOwnerSelf) {
        LCIMMessageSendState status = LCIMMessageSendStateReceived;
        int i;
        for (i = 0; i < 4; i++) {
            if (msgStatuses[i] == message.status) {
                status = lcimMessageStatuses[i];
                break;
            }
        }
        lcimMessage.status = status;
    } else {
        lcimMessage.status = LCIMMessageSendStateReceived;
    }
    return lcimMessage;
}

+ (NSMutableArray *)getAVIMMessages:(NSArray<LCIMMessage *> *)lcimMessages {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (LCIMMessage *message in lcimMessages) {
        AVIMTypedMessage *avimTypedMessage = [self getAVIMTypedMessageWithMessage:message];
        if (avimTypedMessage) {
            [messages addObject:avimTypedMessage];
        }
    }
    return messages;
}
+ (NSMutableArray *)getLCIMMessages:(NSArray *)avimTypedMessage {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (AVIMTypedMessage *msg in avimTypedMessage) {
        LCIMMessage *lcimMsg = [self getLCIMMessageByMessage:msg];
        if (lcimMsg) {
            [messages addObject:lcimMsg];
        }
    }
    return messages;
}

+ (AVIMTypedMessage *)getAVIMTypedMessageWithMessage:(LCIMMessage *)message {
    AVIMTypedMessage *avimTypedMessage;
    switch (message.messageMediaType) {
        case LCIMMessageTypeText: {
            avimTypedMessage = [AVIMTextMessage messageWithText:message.text attributes:nil];
            break;
        }
        case LCIMMessageTypeVideo:
        case LCIMMessageTypeImage: {
            avimTypedMessage = [AVIMImageMessage messageWithText:nil attachedFilePath:message.photoPath attributes:nil];
            break;
        }
        case LCIMMessageTypeVoice: {
            avimTypedMessage = [AVIMAudioMessage messageWithText:nil attachedFilePath:message.voicePath attributes:nil];
            break;
        }
            
        case LCIMMessageTypeEmotion:
            avimTypedMessage = [AVIMEmotionMessage messageWithEmotionPath:message.emotionName];
            break;
            
        case LCIMMessageTypeLocation: {
            //TODO:
            avimTypedMessage = [AVIMLocationMessage messageWithText:message.geolocations
                                                           latitude:message.location.coordinate.latitude
                                                          longitude:message.location.coordinate.longitude
                                                         attributes:nil];
            break;
        case LCIMMessageTypeSystem:
        case LCIMMessageTypeUnknow:
            //TODO:
            break;
        }
    }
    avimTypedMessage.sendTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return avimTypedMessage;
}

- (void)loadMessagesWhenInit {
    if (self.parentViewController.loadingMoreMessage) {
        return;
    } else {
        self.parentViewController.loadingMoreMessage = YES;
        [[self class] queryAndCacheMessagesWithTimestamp:0 block:^(NSArray *avimTypedMessage, NSError *error) {
            BOOL succeed = [self.parentViewController filterAVIMError:error];
            if (succeed) {
                // 失败消息加到末尾，因为 SDK 缓存不保存它们
                //TODO: why only when the net is ok, can the failed messages load fast
                NSMutableArray *lcimSucceedMessags = [LCIMChatViewModel getLCIMMessages:avimTypedMessage];
                [self addMessages:lcimSucceedMessags];
                //                [NSMutableArray arrayWithArray:lcimSucceedMessags];
                NSArray<LCIMMessage *> *failedMessages = [[LCIMConversationService sharedInstance] selectFailedMessagesByConversationId:[LCIMConversationService sharedInstance].currentConversation.conversationId];
                NSMutableArray *allFailedAVIMMessages = [LCIMChatViewModel getAVIMMessages:failedMessages];
                NSMutableArray *allMessages = [NSMutableArray arrayWithArray:avimTypedMessage];
                //TODO:
                //                [allMessages addObjectsFromArray:[allFailedAVIMMessages copy]];
                //                [self.dataArray addObjectsFromArray:failedMessages];
                self.avimTypedMessage = allMessages;
                dispatch_async(dispatch_get_main_queue(),^{
                    [self.parentViewController.tableView reloadData];
                    [self.parentViewController scrollToBottomAnimated:NO];
                });
                
                if (self.avimTypedMessage.count > 0) {
                    [self updateConversationAsRead];
                }
                
                // 如果连接上，则重发所有的失败消息。若夹杂在历史消息中间不好处理
                if ([LCIMSessionService sharedInstance].connect) {
                    //TODO:
                    //                    for (NSInteger row = self.chatViewModel.dataArray.count; row < allMessages.count; row ++) {
                    //                        [self resendMessageAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] discardIfFailed:YES];
                    //                    }
                }
            }
            self.parentViewController.loadingMoreMessage = NO;
        }];
    }
}

+ (void)queryAndCacheMessagesWithTimestamp:(int64_t)timestamp block:(AVIMArrayResultBlock)block {
    [[LCIMConversationService sharedInstance] queryTypedMessagesWithConversation:[LCIMConversationService sharedInstance].currentConversation
                                                                       timestamp:timestamp
                                                                           limit:kLCIMOnePageSize
                                                                           block:^(NSArray *avimTypedMessage, NSError *error) {
                                                                               if (error) {
                                                                                   !block ?: block(avimTypedMessage, error);
                                                                               } else {
                                                                                   [LCIMConversationService cacheMessages:avimTypedMessage callback:^(BOOL succeeded, NSError *error) {
                                                                                       !block ?: block(avimTypedMessage, error);
                                                                                   }];
                                                                               }
                                                                           }];
}

- (void)loadOldMessages {
    if (self.dataArray.count == 0 || self.parentViewController.loadingMoreMessage) {
        return;
    }
    self.parentViewController.loadingMoreMessage = YES;
    AVIMTypedMessage *msg = [self.avimTypedMessage objectAtIndex:0];
    int64_t timestamp = msg.sendTimestamp;
    [[self class] queryAndCacheMessagesWithTimestamp:timestamp block:^(NSArray *avimTypedMessage, NSError *error) {
        self.parentViewController.shouldLoadMoreMessagesScrollToTop = YES;
        if ([self.parentViewController filterAVIMError:error]) {
            if (avimTypedMessage.count == 0 || avimTypedMessage.count < kLCIMOnePageSize) {
                self.parentViewController.shouldLoadMoreMessagesScrollToTop = NO;
                self.parentViewController.loadingMoreMessage = NO;
                return;
            }
            NSMutableArray *lcimMessages = [[[self class] getLCIMMessages:avimTypedMessage] mutableCopy];
            NSMutableArray *newMessages = [NSMutableArray arrayWithArray:avimTypedMessage];
            [newMessages addObjectsFromArray:self.avimTypedMessage];
            self.avimTypedMessage = newMessages;
            [self insertOldMessages:[self topMessagesWithSystemMessages:lcimMessages] completion: ^{
                self.parentViewController.loadingMoreMessage = NO;
            }];
        } else {
            self.parentViewController.loadingMoreMessage = NO;
        }
    }];
}

static CGPoint  delayOffset = {0.0};
- (void)insertOldMessages:(NSArray *)oldMessages completion:(void (^)())completion{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableArray *messages = [NSMutableArray arrayWithArray:oldMessages];
        [messages addObjectsFromArray:self.dataArray];
        delayOffset = self.parentViewController.tableView.contentOffset;
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:oldMessages.count];
        [oldMessages enumerateObjectsUsingBlock:^(LCIMMessage *message, NSUInteger idx, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            [indexPaths addObject:indexPath];
            NSString *identifier = [LCIMCellIdentifierFactory cellIdentifierForMessageConfiguration:message];
            delayOffset.y += [self.parentViewController.tableView fd_heightForCellWithIdentifier:identifier cacheByIndexPath:indexPath configuration:^(id cell) {
                [cell configureCellWithData:message];
            }];
        }];
        
        dispatch_async(dispatch_get_main_queue(),^{
            [UIView setAnimationsEnabled:NO];
            [self.parentViewController.tableView beginUpdates];
            self.dataArray = messages;
            [self.parentViewController.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
            [self.parentViewController.tableView setContentOffset:delayOffset animated:NO];
            [self.parentViewController.tableView endUpdates];
            [UIView setAnimationsEnabled:YES];
            completion();
        });
    });
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.parentViewController.shouldLoadMoreMessagesScrollToTop) {
        if (scrollView.contentOffset.y <= -20 && scrollView.contentOffset.y >= -44) {
            if (!self.parentViewController.loadingMoreMessage) {
                [self.parentViewController loadMoreMessagesScrollTotop];
            }
        }
    }
}

#pragma mark - conversations store

- (void)updateConversationAsRead {
    AVIMConversation *conversation = [LCIMConversationService sharedInstance].currentConversation;
    if (!conversation) {
        NSAssert(conversation, @"currentConversation is nil");
        return;
    }
    [[LCIMConversationService sharedInstance] insertConversation:conversation];
    [[LCIMConversationService sharedInstance] updateUnreadCountToZeroWithConversation:conversation];
    [[LCIMConversationService sharedInstance] updateMentioned:NO conversation:conversation];
    [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationUnreadsUpdated object:nil];
}

- (void)getAllImageMessagesForMessage:(LCIMMessage *)message allImageMessageImages:(NSArray **)allImageMessageImages selectedMessageIndex:(NSNumber **)selectedMessageIndex {
    NSMutableArray *allImageMessageImages_ = [[NSMutableArray alloc] initWithCapacity:0];
    NSUInteger idx = 0;
    for (LCIMMessage *message_ in self.dataArray) {
        BOOL isImageType = (message_.messageMediaType == LCIMMessageTypeImage || message_.photo || message_.originPhotoURL);
        if (isImageType) {
            UIImage *image = message_.photo;
            if (image) {
                [allImageMessageImages_ addObject:image];
            } else if (message_.originPhotoURL) {
                [allImageMessageImages_ addObject:message_.originPhotoURL];
            } else {
                [allImageMessageImages_ addObject:({
                    NSString *imageName = @"Placeholder_Image";
                    NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
                    UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
                    image;})];
            }
            
            if ((message == message_) && (*selectedMessageIndex == nil)){
                *selectedMessageIndex = @(idx);
            }
            idx++;
        }
    }
    if (*allImageMessageImages == nil) {
        *allImageMessageImages = allImageMessageImages_;
    }
}

@end
