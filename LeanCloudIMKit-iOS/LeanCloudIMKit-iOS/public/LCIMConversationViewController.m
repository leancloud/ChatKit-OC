//
//  LCIMConversationViewController.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/2.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMConversationViewController.h"
#import "LCIMUtil.h"
#import "LCIMKit.h"
#import <CommonCrypto/CommonCrypto.h>
#import "XHDisplayTextViewController.h"
#import "XHDisplayMediaViewController.h"
#import "XHDisplayLocationViewController.h"
#import "XHAudioPlayerHelper.h"
#import "LCIMStatusView.h"
#import "LCIMEmotionUtils.h"
#import "AVIMConversation+LCIMAddition.h"
#import "LCIMSoundManager.h"
#import "LCIMConversationService.h"
#import "AVIMEmotionMessage.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "LCIMSettingService.h"
#import "LCIMConversationService.h"
#import "LCIMConstants.h"

typedef void (^LCIMSendMessageSuccessBlock)(NSString *messageUUID);
typedef void (^LCIMSendMessageSuccessFailedBlock)(NSString *messageUUID, NSError *error);

@interface LCIMConversationViewController ()

#pragma mark - 消息发送

/*!
 * 文本发送
 */
- (void)sendTextMessage:(NSString *)text;

/* 图片发送 包含图片上传交互
 * @param image, 要发送的图片
 * @param useOriginImage, 是否强制发送原图
 */
- (void)sendImageMessage:(UIImage *)image useOriginImage:(BOOL)useOriginImage;
- (void)sendImageMessageData:(NSData *)ImageData useOriginImage:(BOOL)useOriginImage;

/*!
 * 语音发送
 */
- (void)sendVoiceMessage:(NSData*)wavData andTime:(NSTimeInterval)nRecordingTime;

@property (nonatomic, strong, readwrite) AVIMConversation *conversation;

/*!
 * msgs and messages are not repeated, this means online messages, which means sending succeed.
 * When deal with those messages which are sent failed, you must use self.messages instead of this.
 */
@property (nonatomic, strong, readwrite) NSMutableArray *avimTypedMessage;
@property (nonatomic, strong) XHMessageTableViewCell *currentSelectedCell;
@property (nonatomic, strong) NSArray *emotionManagers;
@property (nonatomic, strong) LCIMStatusView *clientStatusView;

@end

@implementation LCIMConversationViewController

#pragma mark -
#pragma mark - initialization Method

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _conversationId = conversationId;
    return self;
}

- (instancetype)initWithPeerId:(NSString *)peerId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _peerId = peerId;
    return self;
}

- (instancetype)initWithConversation:(AVIMConversation *)conversation {
    self = [super init];
    if (!self) {
        return nil;
    }
    _conversation = conversation;
    return self;
}

/**
 *  lazy load conversation
 *
 *  @return AVIMConversation
 */
- (AVIMConversation *)conversation {
    if (_conversation == nil) {
        do {
            /* If object is clean, ignore save request. */
            if (_peerId) {
                [[LCIMConversationService sharedInstance] fecthConversationWithPeerId:self.peerId callback:^(AVIMConversation *conversation, NSError *error) {
                    if (!error) {
                        [self refreshConversation:conversation];
                    }
                }];
                break;
            }
            /* If object is clean, ignore save request. */
            if (_conversation) {
                [[LCIMConversationService sharedInstance] fecthConversationWithConversationId:self.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
                    if (!error) {
                        [self refreshConversation:conversation];
                    }
                }];
                break;
            }
        } while (NO);
    }
    return _conversation;
}

#pragma mark -
#pragma mark - UIViewController Life

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.loadingMoreMessage = NO;
        _avimTypedMessage = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initBarButton];
    [self initBottomMenuAndEmotionView];
    [self.view addSubview:self.clientStatusView];
    [[LCIMUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCIMUserModelDelegate> user, NSError *error) {
        // 设置自身用户名
        self.messageSender = user.name;
    }];
    [LCIMConversationService sharedInstance].chattingConversationId = self.conversation.conversationId;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveMessage:) name:LCIMNotificationMessageReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageDelivered:) name:LCIMNotificationMessageDelivered object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshConversation:) name:LCIMNotificationConversationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusView) name:LCIMNotificationConnectivityUpdated object:nil];
    [self updateStatusView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [LCIMConversationService sharedInstance].chattingConversationId = self.conversation.conversationId;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [LCIMConversationService sharedInstance].chattingConversationId = nil;
    if (self.avimTypedMessage.count > 0) {
        [self updateConversationAsRead];
    }
    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
}

#pragma mark - ui init

- (void)initBarButton {
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backBtn];
}

- (NSString *)imageBuddlePathForImage:(NSString *)imageName {
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"ChatKeyboard.bundle/%@", imageName];
    return imageNameWithBundlePath;
}

- (void)initBottomMenuAndEmotionView {
    NSMutableArray *shareMenuItems = [NSMutableArray array];
    NSArray *plugIcons = @[ [self imageBuddlePathForImage:@"sharemore_pic"], [self imageBuddlePathForImage:@"sharemore_video"] ];
    NSArray *plugTitle = @[@"照片", @"拍摄"];
    for (NSString *plugIcon in plugIcons) {
        XHShareMenuItem *shareMenuItem = [[XHShareMenuItem alloc] initWithNormalIconImage:[UIImage imageNamed:plugIcon] title:[plugTitle objectAtIndex:[plugIcons indexOfObject:plugIcon]]];
        [shareMenuItems addObject:shareMenuItem];
    }
    self.shareMenuItems = shareMenuItems;
    [self.shareMenuView reloadData];
    
    _emotionManagers = [LCIMEmotionUtils emotionManagers];
    self.emotionManagerView.isShowEmotionStoreButton = YES;
    [self.emotionManagerView reloadData];
}

- (void)refreshConversation:(AVIMConversation *)conversation {
    _conversation = conversation;
    _conversationId = conversation.conversationId;
    self.title = conversation.lcim_title;
    [LCIMConversationService sharedInstance].currentConversation = conversation;;
    [self loadMessagesWhenInit];
}

#pragma mark - connect status view

- (LCIMStatusView *)clientStatusView {
    if (_clientStatusView == nil) {
        _clientStatusView = [[LCIMStatusView alloc] initWithFrame:CGRectMake(0, 0, self.messageTableView.frame.size.width, LCIMStatusViewHight)];
        _clientStatusView.hidden = YES;
    }
    return _clientStatusView;
}

- (void)updateStatusView {
    if ([LCIMSessionService sharedInstance].connect) {
        self.clientStatusView.hidden = YES;
    } else {
        self.clientStatusView.hidden = NO;
    }
}

- (void)getAllImageMessageViewsForMessage:(id<XHMessageModel>)message allImageMessageViews:(NSArray<UIImageView *> **)allImageMessageViews selectedMessageView:(UIImageView **)selectedMessageView {
    NSMutableArray *allImageMessageViews_ = [[NSMutableArray alloc] initWithCapacity:0];
    for (XHMessage *message_ in self.messages) {
        if (message_.messageMediaType == XHBubbleMessageMediaTypePhoto) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:message_.photo];
            if (message.thumbnailUrl) {
                [imageView sd_setImageWithURL:[NSURL URLWithString:[message thumbnailUrl]] placeholderImage:({
                    NSString *imageName = @"Placeholder_Image";
                    NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
                    UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
                    image;})
                 ];
            }
            [allImageMessageViews_ addObject:imageView];
            if (message == message_ && *selectedMessageView == nil) {
                *selectedMessageView = imageView;
            }
        }
    }
    if (*allImageMessageViews == nil) {
        *allImageMessageViews = allImageMessageViews_;
    }
}

#pragma mark - XHMessageTableViewCell delegate

- (void)multiMediaMessageDidSelectedOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath onMessageTableViewCell:(XHMessageTableViewCell *)messageTableViewCell {
    UIViewController *disPlayViewController;
    switch (message.messageMediaType) {
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypePhoto: {
            //TODO:
            //          XHImageViewer *imageViewer = [[XHImageViewer alloc] init];
            //            imageViewer.delegate = self;
            //            NSArray *allImageMessageViews = nil;
            //            UIImageView *selectedMessageView = nil;
            //            [self getAllImageMessageViewsForMessage:message allImageMessageViews:&allImageMessageViews selectedMessageView:&selectedMessageView];
            //            [imageViewer showWithImageViews:allImageMessageViews selectedView:selectedMessageView];
            XHDisplayMediaViewController *messageDisplayTextView = [[XHDisplayMediaViewController alloc] init];
            messageDisplayTextView.message = message;
            disPlayViewController = messageDisplayTextView;
            break;
        }
            
        case XHBubbleMessageMediaTypeVoice: {
            //TODO:
            // Mark the voice as read and hide the red dot.
            //message.isRead = YES;
            //messageTableViewCell.messageBubbleView.voiceUnreadDotImageView.hidden = YES;
            [[XHAudioPlayerHelper shareInstance] setDelegate:self];
            if (_currentSelectedCell) {
                [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
            }
            if (_currentSelectedCell == messageTableViewCell) {
                [messageTableViewCell.messageBubbleView.animationVoiceImageView stopAnimating];
                [[XHAudioPlayerHelper shareInstance] stopAudio];
                self.currentSelectedCell = nil;
            } else {
                self.currentSelectedCell = messageTableViewCell;
                [messageTableViewCell.messageBubbleView.animationVoiceImageView startAnimating];
                [[XHAudioPlayerHelper shareInstance] managerAudioWithFileName:message.voicePath toPlay:YES];
            }
            break;
        }
            
        case XHBubbleMessageMediaTypeEmotion:
            DLog(@"facePath : %@", message.emotionPath);
            break;
            
        case XHBubbleMessageMediaTypeLocalPosition: {
            DLog(@"facePath : %@", message.localPositionPhoto);
            XHDisplayLocationViewController *displayLocationViewController = [[XHDisplayLocationViewController alloc] init];
            displayLocationViewController.message = message;
            disPlayViewController = displayLocationViewController;
            break;
        }
    }
    if (disPlayViewController) {
        [self.navigationController pushViewController:disPlayViewController animated:NO];
    }
}

- (void)didDoubleSelectedOnTextMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    DLog(@"text : %@", message.text);
    XHDisplayTextViewController *displayTextViewController = [[XHDisplayTextViewController alloc] init];
    displayTextViewController.message = message;
    [self.navigationController pushViewController:displayTextViewController animated:NO];
}

- (void)didSelectedAvatorOnMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    //    AVIMTypedMessage *msg = self.msgs[indexPath.row];
    //    if ([msg.clientId isEqualToString:[CDChatManager manager].clientId] == NO) {
    //        CDUserInfoVC *userInfoVC = [[CDUserInfoVC alloc] initWithUser:[[CDCacheManager manager] lookupUser:msg.clientId]];
    //        [self.navigationController pushViewController:userInfoVC animated:YES];
    //    }
}

- (void)menuDidSelectedAtBubbleMessageMenuSelecteType:(XHBubbleMessageMenuSelecteType)bubbleMessageMenuSelecteType {
}

- (void)didRetrySendMessage:(id<XHMessageModel>)message atIndexPath:(NSIndexPath *)indexPath {
    [self resendMessageAtIndexPath:indexPath discardIfFailed:false];
}

#pragma mark - XHAudioPlayerHelper Delegate

- (void)didAudioPlayerStopPlay:(AVAudioPlayer *)audioPlayer {
    if (!_currentSelectedCell) {
        return;
    }
    [_currentSelectedCell.messageBubbleView.animationVoiceImageView stopAnimating];
    self.currentSelectedCell = nil;
}

#pragma mark - XHEmotionManagerView DataSource

- (NSInteger)numberOfEmotionManagers {
    return self.emotionManagers.count;
}

- (XHEmotionManager *)emotionManagerForColumn:(NSInteger)column {
    return [self.emotionManagers objectAtIndex:column];
}

- (NSArray *)emotionManagersAtManager {
    return self.emotionManagers;
}

#pragma mark - XHMessageTableViewController Delegate

- (void)loadMoreMessagesScrollTotop {
    [self loadOldMessages];
}

#pragma mark - didSend delegate

//发送文本消息的回调方法
- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    if ([text length] > 0 ) {
        XHMessage *xhMessage = [[XHMessage alloc] initWithText:[LCIMEmotionUtils emojiStringFromString:text] sender:sender timestamp:date];
        [self sendMessage:xhMessage];
        [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeText];
    }
}

//发送图片消息的回调方法
- (void)didSendPhoto:(UIImage *)photo fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    [self sendImage:photo fromSender:sender];
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypePhoto];
}

// 发送视频消息的回调方法
- (void)didSendVideoConverPhoto:(UIImage *)videoConverPhoto videoPath:(NSString *)videoPath fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    AVIMVideoMessage *sendVideoMessage = [AVIMVideoMessage messageWithText:nil attachedFilePath:videoPath attributes:nil];
    [self sendMessage:sendVideoMessage];
}

// 发送语音消息的回调方法
- (void)didSendVoice:(NSString *)voicePath voiceDuration:(NSString *)voiceDuration fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    [self sendVoiceWithPath:voicePath fromSender:sender];
}

// 发送表情消息的回调方法
- (void)didSendEmotion:(NSString *)emotion fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    if ([emotion hasPrefix:@":"]) {
        // 普通表情
        UITextView *textView = self.messageInputView.inputTextView;
        NSRange range = [textView selectedRange];
        NSMutableString *str = [[NSMutableString alloc] initWithString:textView.text];
        [str deleteCharactersInRange:range];
        [str insertString:emotion atIndex:range.location];
        textView.text = [LCIMEmotionUtils emojiStringFromString:str];
        textView.selectedRange = NSMakeRange(range.location + emotion.length, 0);
        //TODO:
        [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeEmotion];
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:emotion ofType:@"gif"];
        XHMessage *message = [[XHMessage alloc] initWithEmotionPath:path emotionName:emotion sender:sender timestamp:nil];
        [self sendMessage:message];
        [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeEmotion];
    }
}

- (void)didSendGeoLocationsPhoto:(UIImage *)geoLocationsPhoto geolocations:(NSString *)geolocations location:(CLLocation *)location fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    //TODO:
    [self finishSendMessageWithBubbleMessageType:XHBubbleMessageMediaTypeLocalPosition];
}

#pragma mark -  UI config Delegate Method

// 是否显示时间轴Label的回调方法
- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        //FIXME:这里只能设NO, 不然会引起显示异常
        return NO;
    }  else {
        XHMessage *msg = [self.messages objectAtIndex:indexPath.row];
        XHMessage *lastMsg = [self.messages objectAtIndex:indexPath.row - 1];
        int interval = [msg.timestamp timeIntervalSinceDate:lastMsg.timestamp];
        if (interval > 60 * 3) {
            return YES;
        } else {
            return NO;
        }
    }
}

- (BOOL)shouldDisplayPeerName {
    return YES;
}

// 配置Cell的样式或者字体
- (void)configureCell:(XHMessageTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    XHMessage *msg = [self.messages objectAtIndex:indexPath.row];
    if ([self shouldDisplayTimestampForRowAtIndexPath:indexPath]) {
        NSDate *ts = msg.timestamp;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM-dd HH:mm"];
        NSString *str = [dateFormatter stringFromDate:ts];
        cell.timestampLabel.text = str;
    }
    SETextView *textView = cell.messageBubbleView.displayTextView;
    if (msg.bubbleMessageType == XHBubbleMessageTypeSending) {
        [textView setTextColor:[UIColor whiteColor]];
    } else {
        [textView setTextColor:[UIColor blackColor]];
    }
}

// 协议回掉是否支持用户手动滚动
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

- (void)didSelecteShareMenuItem:(XHShareMenuItem *)shareMenuItem atIndex:(NSInteger)index {
    [super didSelecteShareMenuItem:shareMenuItem atIndex:index];
}

#pragma mark - @ reference other

- (void)didInputAtSignOnMessageTextView:(XHMessageTextView *)messageInputTextView {
//    if (self.conversation.type == LCIMConversationTypeGroup) {
//        [self performSelector:@selector(goSelectMemberVC) withObject:nil afterDelay:0];
        // weird , call below function not input @
        //        [self goSelectMemberVC];
//    }
}

#pragma mark - alert and async utils

- (void)runInMainQueue:(void (^)())queue {
    dispatch_async(dispatch_get_main_queue(), queue);
}

- (void)runInGlobalQueue:(void (^)())queue {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), queue);
}

#pragma mark - LeanCloud

#pragma mark - conversations store

- (void)updateConversationAsRead {
    [[LCIMConversationService sharedInstance] insertConversation:self.conversation];
    [[LCIMConversationService sharedInstance] updateUnreadCountToZeroWithConversation:self.conversation];
    [[LCIMConversationService sharedInstance] updateMentioned:NO conversation:self.conversation];
    [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationUnreadsUpdated object:nil];
}

#pragma mark - send message

- (void)sendImage:(UIImage *)image fromSender:(NSString *)sender {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    NSString *path = [[LCIMSettingService sharedInstance] tmpPath];
    NSError *error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    if (error == nil) {
        XHMessage *message = [[XHMessage alloc]
                              initWithPhoto:image
                              photoPath:path
                              thumbnailUrl:nil
                              originPhotoUrl:nil
                              sender:sender
                              timestamp:nil
                              ];
        [self sendMessage:message];
    } else {
        [self alert:@"write image to file error"];
    }
}

- (void)sendVoiceWithPath:(NSString *)voicePath fromSender:(NSString *)sender {
    XHMessage *message = [[XHMessage alloc] initWithVoicePath:voicePath
                                                     voiceUrl:nil
                                                voiceDuration:nil
                                                       sender:sender
                                                    timestamp:nil
                          ];
    [self sendMessage:message];
}

- (void)sendLocationWithLatitude:(double)latitude longitude:(double)longitude address:(NSString *)address {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    XHMessage *message = [[XHMessage alloc] initWithLocalPositionPhoto:[UIImage imageNamed:@"Fav_Cell_Loc"] geolocations:nil location:location sender:nil timestamp:nil];
    [self sendMessage:message];
}

- (AVIMTypedMessage *)getAVIMTypedMessageWithMessage:(XHMessage *)message {
    AVIMTypedMessage *avimTypedMessage;
    switch (message.messageMediaType) {
        case XHBubbleMessageMediaTypeText: {
            avimTypedMessage = [AVIMTextMessage messageWithText:[LCIMEmotionUtils plainStringFromEmojiString:message.text] attributes:nil];
            break;
        }
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypePhoto: {
            avimTypedMessage = [AVIMImageMessage messageWithText:nil attachedFilePath:message.photoPath attributes:nil];
            break;
        }
        case XHBubbleMessageMediaTypeVoice: {
            avimTypedMessage = [AVIMAudioMessage messageWithText:nil attachedFilePath:message.voicePath attributes:nil];
            break;
        }
            
        case XHBubbleMessageMediaTypeEmotion:
            avimTypedMessage = [AVIMEmotionMessage messageWithEmotionPath:message.emotionName];
            break;
            
        case XHBubbleMessageMediaTypeLocalPosition: {
            //TODO:
            // avimTypedMessage = [AVIMLocationMessage messageWithText:nil latitude:message.latitude longitude:message.longitude attributes:nil];
            break;
        }
    }
    avimTypedMessage.sendTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    return avimTypedMessage;
}

- (void)sendMessage:(XHMessage *)message {
    [self sendMessage:message success:^(NSString *messageUUID) {
        [[LCIMSoundManager defaultManager] playSendSoundIfNeed];
    } failed:^(NSString *messageUUID, NSError *error) {
        message.messageId = messageUUID;
        //TODO:
//        [[LCIMConversationService sharedInstance] insertFailedXHMessage:message];
    }];
}

- (void)sendMessage:(XHMessage *)message success:(LCIMSendMessageSuccessBlock)success failed:(LCIMSendMessageSuccessFailedBlock)failed {
    message.conversationId = self.conversation.conversationId;
    message.status = XHMessageStatusSending;
    AVIMTypedMessage *avimTypedMessage = [self getAVIMTypedMessageWithMessage:message];
    [self.avimTypedMessage addObject:avimTypedMessage];
    [self preloadMessageToTableView:message];
    
    // if `message.messageId` is not nil, it is a failed message being resended.
    NSString *messageUUID = (message.messageId) ? message.messageId : [[NSUUID UUID] UUIDString];
    [[LCIMConversationService sharedInstance] sendMessage:avimTypedMessage conversation:self.conversation callback:^(BOOL succeeded, NSError *error) {
        if (error) {
            message.status = XHMessageStatusFailed;
            !failed ?: failed(messageUUID, error);
        } else {
            message.status = XHMessageStatusSent;
            !success ?: success(messageUUID);
        }
        //TODO:
        //???:should I cache message even failed
        [self cacheMessages:@[avimTypedMessage] callback:nil];
        dispatch_async(dispatch_get_main_queue(),^{
            NSUInteger index = [self.messages indexOfObject:message];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.messageTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }];
}

- (void)resendMessageAtIndexPath:(NSIndexPath *)indexPath discardIfFailed:(BOOL)discardIfFailed {
    XHMessage *xhMessage =  self.messages[indexPath.row];
    [self.messages removeObjectAtIndex:indexPath.row];
    [self.avimTypedMessage removeObjectAtIndex:indexPath.row];
    [self.messageTableView reloadData];
    [self sendMessage:xhMessage success:^(NSString *messageUUID) {
        [[LCIMConversationService sharedInstance] deleteFailedMessageByRecordId:messageUUID];
    } failed:^(NSString *messageUUID, NSError *error) {
        if (discardIfFailed) {
            // 服务器连通的情况下重发依然失败，说明消息有问题，如音频文件不存在，删掉这条消息
            [[LCIMConversationService sharedInstance] deleteFailedMessageByRecordId:messageUUID];
        }
    }];
}

#pragma mark - receive and delivered

- (void)receiveMessage:(NSNotification *)notification {
    AVIMTypedMessage *message = notification.object;
    if ([message.conversationId isEqualToString:self.conversation.conversationId]) {
        if (self.conversation.muted == NO) {
            [[LCIMSoundManager defaultManager] playReceiveSoundIfNeed];
        }
        [self insertMessage:message];
        //        [[LCIMChatManager manager] setZeroUnreadWithConversationId:self.conversation.conversationId];
        //        [[NSNotificationCenter defaultCenter] postNotificationName:LCIMNotificationMessageReceived object:nil];
    }
}

- (void)onMessageDelivered:(NSNotification *)notification {
    AVIMTypedMessage *message = notification.object;
    if ([message.conversationId isEqualToString:self.conversation.conversationId]) {
        AVIMTypedMessage *foundMessage;
        NSInteger pos;
        for (pos = 0; pos < self.avimTypedMessage.count; pos++) {
            AVIMTypedMessage *msg = self.avimTypedMessage[pos];
            if ([msg.messageId isEqualToString:message.messageId]) {
                foundMessage = msg;
                break;
            }
        }
        if (foundMessage !=nil) {
            XHMessage *xhMsg = [self getXHMessageByMsg:foundMessage];
            [self.messages setObject:xhMsg atIndexedSubscript:pos];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:pos inSection:0];
            [self.messageTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self scrollToBottomAnimated:YES];
        }
    }
}

#pragma mark - modal convert

- (NSDate *)getTimestampDate:(int64_t)timestamp {
    return [NSDate dateWithTimeIntervalSince1970:timestamp / 1000];
}

- (XHMessage *)getXHMessageByMsg:(AVIMTypedMessage *)message {
    id<LCIMUserModelDelegate> fromUser = [[LCIMUserSystemService sharedInstance] getProfileForUserId:message.clientId error:nil];
    XHMessage *xhMessage;
    NSDate *time = [self getTimestampDate:message.sendTimestamp];
    if (message.mediaType == kAVIMMessageMediaTypeText) {
        AVIMTextMessage *textMsg = (AVIMTextMessage *)message;
        xhMessage = [[XHMessage alloc] initWithText:[LCIMEmotionUtils emojiStringFromString:textMsg.text] sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeAudio) {
        AVIMAudioMessage *audioMsg = (AVIMAudioMessage *)message;
        NSString *duration = [NSString stringWithFormat:@"%.0f", audioMsg.duration];
        xhMessage = [[XHMessage alloc] initWithVoicePath:audioMsg.file.localPath voiceUrl:nil voiceDuration:duration sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeLocation) {
        AVIMLocationMessage *locationMsg = (AVIMLocationMessage *)message;
        xhMessage = [[XHMessage alloc] initWithLocalPositionPhoto:[UIImage imageNamed:@"Fav_Cell_Loc"] geolocations:locationMsg.text location:[[CLLocation alloc] initWithLatitude:locationMsg.latitude longitude:locationMsg.longitude] sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeImage) {
        AVIMImageMessage *imageMsg = (AVIMImageMessage *)message;
        UIImage *image;
        NSError *error;
        NSData *data = [imageMsg.file getData:&error];
        if (error) {
            DLog(@"get Data error: %@", error);
        } else {
            image = [UIImage imageWithData:data];
        }
        //TODO: image and photoPath may all be nil
        xhMessage = [[XHMessage alloc] initWithPhoto:image photoPath:nil thumbnailUrl:nil originPhotoUrl:nil sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeEmotion) {
        AVIMEmotionMessage *emotionMsg = (AVIMEmotionMessage *)message;
        NSString *path = [[NSBundle mainBundle] pathForResource:emotionMsg.emotionPath ofType:@"gif"];
        xhMessage = [[XHMessage alloc] initWithEmotionPath:path sender:fromUser.name timestamp:time];
    } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
        AVIMVideoMessage *videoMsg = (AVIMVideoMessage *)message;
        NSString *path = [[LCIMSettingService sharedInstance] videoPathOfMessage:videoMsg];
        xhMessage = [[XHMessage alloc] initWithVideoConverPhoto:[XHMessageVideoConverPhotoFactory videoConverPhotoWithVideoPath:path] videoPath:path videoUrl:nil sender:fromUser.name timestamp:time];
    } else {
        xhMessage = [[XHMessage alloc] initWithText:@"未知消息" sender:fromUser.name timestamp:time];
        DLog("unkonwMessage");
    }
    
    xhMessage.avator = nil;
    xhMessage.avatorUrl = [fromUser avatorURL];
    
    if ([[LCIMSessionService sharedInstance].clientId isEqualToString:message.clientId]) {
        xhMessage.bubbleMessageType = XHBubbleMessageTypeSending;
    } else {
        xhMessage.bubbleMessageType = XHBubbleMessageTypeReceiving;
    }
    NSInteger msgStatuses[4] = { AVIMMessageStatusSending, AVIMMessageStatusSent, AVIMMessageStatusDelivered, AVIMMessageStatusFailed };
    NSInteger xhMessageStatuses[4] = { XHMessageStatusSending, XHMessageStatusSent, XHMessageStatusReceived, XHMessageStatusFailed };
    
    if (xhMessage.bubbleMessageType == XHBubbleMessageTypeSending) {
        XHMessageStatus status = XHMessageStatusReceived;
        int i;
        for (i = 0; i < 4; i++) {
            if (msgStatuses[i] == message.status) {
                status = xhMessageStatuses[i];
                break;
            }
        }
        xhMessage.status = status;
    } else {
        xhMessage.status = XHMessageStatusReceived;
    }
    return xhMessage;
}

- (NSMutableArray *)getXHMessages:(NSArray *)avimTypedMessage {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (AVIMTypedMessage *msg in avimTypedMessage) {
        XHMessage *xhMsg = [self getXHMessageByMsg:msg];
        if (xhMsg) {
            [messages addObject:xhMsg];
        }
    }
    return messages;
}

- (NSMutableArray *)getAVIMMessages:(NSArray<XHMessage *> *)xhMessages {
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (XHMessage *message in xhMessages) {
        AVIMTypedMessage *avimTypedMessage = [self getAVIMTypedMessageWithMessage:message];
        if (avimTypedMessage) {
            [messages addObject:avimTypedMessage];
        }
    }
    return messages;
}

#pragma mark - query messages

- (void)queryAndCacheMessagesWithTimestamp:(int64_t)timestamp block:(AVIMArrayResultBlock)block {
    [[LCIMConversationService sharedInstance] queryTypedMessagesWithConversation:self.conversation timestamp:timestamp limit:kLCIMOnePageSize block:^(NSArray *avimTypedMessage, NSError *error) {
        if (error) {
            !block ?: block(avimTypedMessage, error);
        } else {
            [self cacheMessages:avimTypedMessage callback:^(BOOL succeeded, NSError *error) {
                !block ?: block(avimTypedMessage, error);
            }];
        }
    }];
}

- (void)loadMessagesWhenInit {
    if (self.loadingMoreMessage) {
        return;
    } else {
        self.loadingMoreMessage = YES;
        [self queryAndCacheMessagesWithTimestamp:0 block:^(NSArray *avimTypedMessage, NSError *error) {
            BOOL succeed = [self filterAVIMError:error];
            if (succeed) {
                // 失败消息加到末尾，因为 SDK 缓存不保存它们
                //TODO: why only when the net is ok, can the failed messages load fast
                NSMutableArray *xhSucceedMessags = [self getXHMessages:avimTypedMessage];
                self.messages = [NSMutableArray arrayWithArray:xhSucceedMessags];
                NSArray<XHMessage *> *failedMessages = [[LCIMConversationService sharedInstance] selectFailedMessagesByConversationId:self.conversation.conversationId];
                NSMutableArray *allFailedAVIMMessages = [self getAVIMMessages:failedMessages];
                NSMutableArray *allMessages = [NSMutableArray arrayWithArray:avimTypedMessage];
                [allMessages addObjectsFromArray:[allFailedAVIMMessages copy]];
                [self.messages addObjectsFromArray:failedMessages];
                self.avimTypedMessage = allMessages;
                [self.messageTableView reloadData];
                [self scrollToBottomAnimated:NO];
                
                if (self.avimTypedMessage.count > 0) {
                    [self updateConversationAsRead];
                }
                
                // 如果连接上，则重发所有的失败消息。若夹杂在历史消息中间不好处理
                if ([LCIMSessionService sharedInstance].connect) {
                    for (NSInteger row = self.messages.count; row < allMessages.count; row ++) {
                        [self resendMessageAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] discardIfFailed:YES];
                    }
                }
            }
            self.loadingMoreMessage = NO;
        }];
    }
}

- (void)loadOldMessages {
    if (self.messages.count == 0 || self.loadingMoreMessage) {
        return;
    }
    self.loadingMoreMessage = YES;
    AVIMTypedMessage *msg = [self.avimTypedMessage objectAtIndex:0];
    int64_t timestamp = msg.sendTimestamp;
    [self queryAndCacheMessagesWithTimestamp:timestamp block:^(NSArray *avimTypedMessage, NSError *error) {
        self.shouldLoadMoreMessagesScrollToTop = YES;
        if ([self filterAVIMError:error]) {
            if (avimTypedMessage.count == 0) {
                self.shouldLoadMoreMessagesScrollToTop = NO;
                self.loadingMoreMessage = NO;
                return;
            }
            NSMutableArray *xhMsgs = [[self getXHMessages:avimTypedMessage] mutableCopy];
            NSMutableArray *newMsgs = [NSMutableArray arrayWithArray:avimTypedMessage];
            [newMsgs addObjectsFromArray:self.avimTypedMessage];
            self.avimTypedMessage = newMsgs;
            [self insertOldMessages:xhMsgs completion: ^{
                self.loadingMoreMessage = NO;
            }];
        } else {
            self.loadingMoreMessage = NO;
        }
    }];
}

- (void)cacheMessages:(NSArray<AVIMTypedMessage *> *)messages callback:(AVBooleanResultBlock)callback {
    [self runInGlobalQueue:^{
        NSMutableSet *userIds = [[NSMutableSet alloc] init];
        for (AVIMTypedMessage *message in messages) {
            [userIds addObject:message.clientId];
            if (message.mediaType == kAVIMMessageMediaTypeImage || message.mediaType == kAVIMMessageMediaTypeAudio) {
                AVFile *file = message.file;
                if (file && file.isDataAvailable == NO) {
                    NSError *error;
                    // 下载到本地
                    NSData *data = [file getData:&error];
                    if (error || data == nil) {
                        DLog(@"download file error : %@", error);
                    }
                }
            } else if (message.mediaType == kAVIMMessageMediaTypeVideo) {
                NSString *path = [[LCIMSettingService sharedInstance] videoPathOfMessage:(AVIMVideoMessage *)message];
                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    NSError *error;
                    NSData *data = [message.file getData:&error];
                    if (error) {
                        DLog(@"download file error : %@", error);
                    } else {
                        [data writeToFile:path atomically:YES];
                    }
                }
            }
        }

        [[LCIMUserSystemService sharedInstance] cacheUsersWithIds:userIds callback:^(BOOL succeeded, NSError *error) {
            [self runInMainQueue:^{
                !callback ?: callback(succeeded, error);
            }];
        }];
    }];
}

- (void)preloadMessageToTableView:(XHMessage *)message {
    [self.messages addObject:message];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.messageTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self scrollToBottomAnimated:YES];
}

- (void)insertMessage:(AVIMTypedMessage *)message {
    if (self.loadingMoreMessage) {
        return;
    }
    self.loadingMoreMessage = YES;
    [self cacheMessages:@[message] callback:^(BOOL succeeded, NSError *error) {
        if ([self filterAVIMError:error]) {
            XHMessage *xhMessage = [self getXHMessageByMsg:message];
            [self.avimTypedMessage addObject:message];
            [self.messages addObject:xhMessage];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.avimTypedMessage.count -1 inSection:0];
            [self.messageTableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [self scrollToBottomAnimated:YES];
        }
        self.loadingMoreMessage = NO;
    }];
}

- (void)goSelectMemberVC {
//    CDSelectMemberVC *selectMemberVC = [[CDSelectMemberVC alloc] init];
//    selectMemberVC.selectMemberVCDelegate = self;
//    selectMemberVC.conversation = self.conversation;
//    CDBaseNavC *nav = [[CDBaseNavC alloc] initWithRootViewController:selectMemberVC];
//    [self presentViewController:nav animated:YES completion:nil];
}

//TODO:
#pragma mark - CDSelectMemberVCDelegate

//- (void)didSelectMember:(AVUser *)member {
//    self.messageInputView.inputTextView.text = [NSString stringWithFormat:@"%@%@ ", self.messageInputView.inputTextView.text, member.username];
//    [self performSelector:@selector(messageInputViewBecomeFristResponder) withObject:nil afterDelay:0];
//}
//
//- (void)messageInputViewBecomeFristResponder {
//    [self.messageInputView.inputTextView becomeFirstResponder];
//}

@end

