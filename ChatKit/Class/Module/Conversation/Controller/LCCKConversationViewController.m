//
//  LCCKConversationViewController.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudChatKit-iOS ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

//CYLDebugging定义为1表示【debugging】 ，注释、不定义或者0 表示【debugging】
//#define CYLDebugging 1

#import "LCCKConversationViewController.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "LCCKCellRegisterController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCCKConversationService.h"
#import "LCCKUserSystemService.h"
#import "AVIMConversation+LCCKAddition.h"
#import "LCCKStatusView.h"
#import "LCCKSessionService.h"
#import "LCCKConversationService.h"
#import "LCCKSettingService.h"
#import "LCCKSoundManager.h"
#import "LCCKTextFullScreenViewController.h"
#import "LCCKUIService.h"
#import <objc/runtime.h>
#import "UIImage+LCCKExtension.h"

@interface LCCKConversationViewController () <LCCKChatBarDelegate, LCCKAVAudioPlayerDelegate, LCCKChatMessageCellDelegate, LCCKConversationViewModelDelegate>

@property (nonatomic, strong, readwrite) AVIMConversation *conversation;
//@property (copy, nonatomic) NSString *messageSender /**< 正在聊天的用户昵称 */;
//@property (copy, nonatomic) NSString *avatorURL /**< 正在聊天的用户头像 */;
/**< 正在聊天的用户昵称 */
@property (nonatomic, copy) NSString *userId;
/**< 正在聊天的用户头像 */
@property (nonatomic, copy) NSURL *avatorURL;
//@property (assign, nonatomic) LCCKConversationType messageChatType;
@property (nonatomic, strong) LCCKConversationViewModel *chatViewModel;
@property (nonatomic, copy) LCCKConversationHandler conversationHandler;
@property (nonatomic, copy) LCCKBooleanResultBlock loadHistoryMessagesHandler;

@end

@implementation LCCKConversationViewController

- (void)setConversationHandler:(LCCKConversationHandler)conversationHandler {
    _conversationHandler = conversationHandler;
}

- (void)setLoadHistoryMessagesHandler:(LCCKBooleanResultBlock)loadHistoryMessagesHandler {
    _loadHistoryMessagesHandler = loadHistoryMessagesHandler;
}

#pragma mark -
#pragma mark - initialization Method

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self setup];
    _conversationId = conversationId;
    return self;
}

- (instancetype)initWithPeerId:(NSString *)peerId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _peerId = peerId;
    [self setup];
    return self;
}

/**
 *  lazy load conversation
 *
 *  @return AVIMConversation
 */
- (AVIMConversation *)conversation {
    if (_conversation) { return _conversation; }
    //在对象生命周期内，不添加 flag 属性的情况下，防止多次调进这个方法
    if (objc_getAssociatedObject(self, _cmd)) {
        return _conversation;
    } else {
        objc_setAssociatedObject(self, _cmd, @"isFetchingConversation", OBJC_ASSOCIATION_RETAIN);
    }
    do {
        /* If object is clean, ignore save request. */
        if (_peerId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithPeerId:self.peerId callback:^(AVIMConversation *conversation, NSError *error) {
                [self refreshConversation:conversation];
            }];
            break;
        }
        /* If object is clean, ignore save request. */
        if (_conversationId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithConversationId:self.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
                if (!error) {
                    NSString *currentClientId = [LCCKSessionService sharedInstance].clientId;
                    BOOL containsCurrentClientId = [conversation.members containsObject:currentClientId];
                    if (!containsCurrentClientId) {
                        [conversation joinWithCallback:nil];
                    }
                }
                [self refreshConversation:conversation];
            }];
            break;
        }
    } while (NO);
    return _conversation;
}

#pragma mark - Life Cycle

- (void)setup {
    self.loadingMoreMessage = NO;
    self.disableTextShowInFullScreen = NO;
    BOOL clientStatusOpened = [LCCKSessionService sharedInstance].client.status == AVIMClientStatusOpened;
    //    NSAssert(clientStatusOpened, @"client not opened");
    if (!clientStatusOpened) {
        LCCKSessionNotOpenedHandler sessionNotOpenedHandler = [LCCKSessionService sharedInstance].sessionNotOpenedHandler;
        LCCKBooleanResultBlock callback = ^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        };
        !sessionNotOpenedHandler ?: sessionNotOpenedHandler(self, callback);
    }
}

/**
 *  lazy load chatViewModel
 *
 *  @return LCCKConversationViewModel
 */
- (LCCKConversationViewModel *)chatViewModel {
    if (_chatViewModel == nil) {
        LCCKConversationViewModel *chatViewModel = [[LCCKConversationViewModel alloc] initWithParentViewController:self];
        chatViewModel.delegate = self;
        _chatViewModel = chatViewModel;
    }
    return _chatViewModel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self.chatViewModel;
    self.tableView.dataSource = self.chatViewModel;
    self.chatBar.delegate = self;
    [LCCKAVAudioPlayer sharePlayer].delegate = self;
    self.tableView.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:234/255.0f blue:234/255.f alpha:1.0f];
    [self.view addSubview:self.chatBar];
    [self.view addSubview:self.clientStatusView];
    [self updateStatusView];
    [self initBarButton];
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserModelDelegate> user, NSError *error) {
        self.userId = user.userId;
        self.avatorURL = user.avatorURL;
    }];
    if (self.conversation.conversationId) {
        [LCCKConversationService sharedInstance].chattingConversationId = self.conversation.conversationId;
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.conversation.conversationId) {
        [LCCKConversationService sharedInstance].chattingConversationId = self.conversation.conversationId;
    }
}

//TODO:push 到比如图片浏览器，然后pop回来，tableview有偏移，似乎与屏幕作为最低端，而非chatBar最顶端。
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[LCCKAVAudioPlayer sharePlayer] stopAudioPlayer];
    [LCCKAVAudioPlayer sharePlayer].index = NSUIntegerMax;
    [LCCKAVAudioPlayer sharePlayer].URLString = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [LCCKConversationService sharedInstance].chattingConversationId = nil;
    if (self.chatViewModel.avimTypedMessage.count > 0) {
        [self.chatViewModel updateConversationAsRead];
    }
    //TODO:
    //    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

- (void)dealloc {
    //[[XHAudioPlayerHelper shareInstance] setDelegate:nil];
}

#pragma mark - UI init

- (void)initBarButton {
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backBtn];
}

- (void)refreshConversation:(AVIMConversation *)conversation {
    _conversation = conversation;
    self.navigationItem.title = conversation.lcim_title;
    [LCCKConversationService sharedInstance].currentConversation = conversation;;
    [self.chatViewModel loadMessagesWhenInitHandler:^(BOOL succeeded, NSError *error) {
        !_loadHistoryMessagesHandler ?: _loadHistoryMessagesHandler(succeeded, error);
    }];
    !_conversationHandler ?: _conversationHandler(conversation, self);
}

#pragma mark - LCCKChatBarDelegate

- (void)chatBar:(LCCKChatBar *)chatBar sendMessage:(NSString *)message {
    if ([LCCKSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    if ([message length] > 0 ) {
        LCCKMessage *lcimMessage = [[LCCKMessage alloc] initWithText:message
                                                              sender:self.userId
                                                           timestamp:[NSDate date]];
        lcimMessage.messageGroupType = self.conversation.lcim_type;
        [self.chatViewModel sendMessage:lcimMessage];
    }
}

- (void)chatBar:(LCCKChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    if ([LCCKSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    [self sendVoiceWithPath:voiceFileName seconds:seconds];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendPictures:(NSArray<UIImage *> *)pictures{
    if ([LCCKSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    [self sendImages:pictures];
}

- (void)sendImages:(NSArray<UIImage *> *)pictures {
    for (UIImage *image in pictures) {
        [self sendImage:image];
    }
}

- (void)sendImage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    NSString *path = [[LCCKSettingService sharedInstance] tmpPath];
    NSError *error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    UIImage *representationImage = [[UIImage alloc] initWithData:imageData];
    UIImage *thumbnailPhoto = [representationImage lcck_imageByScalingAspectFill];
    if (error == nil) {
        LCCKMessage *message = [[LCCKMessage alloc] initWithPhoto:representationImage
                                                   thumbnailPhoto:thumbnailPhoto
                                                        photoPath:path
                                                     thumbnailURL:nil
                                                   originPhotoURL:nil
                                                           sender:self.userId
                                                        timestamp:[NSDate date]];
        message.messageGroupType = self.conversation.lcim_type;
        [self.chatViewModel sendMessage:message];
    } else {
        [self alert:@"write image to file error"];
    }
}

- (void)sendVoiceWithPath:(NSString *)voicePath seconds:(NSTimeInterval)seconds {
    LCCKMessage *message = [[LCCKMessage alloc] initWithVoicePath:voicePath
                                                         voiceURL:nil
                                                    voiceDuration:[NSString stringWithFormat:@"%@", @(seconds)]
                                                           sender:self.userId
                                                        timestamp:[NSDate date]];
    message.messageGroupType =  self.conversation.lcim_type;
    [self.chatViewModel sendMessage:message];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText{
    LCCKMessage *message = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
        NSString *imageName = @"message_sender_location";
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"MessageBubble.bundle/%@", imageName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        image;})
                                                              geolocations:locationText
                                                                  location:[[CLLocation alloc] initWithLatitude:locationCoordinate.latitude
                                                                                                      longitude:locationCoordinate.longitude]
                                                                    sender:self.userId
                                                                 timestamp:[NSDate date]];
    [self.chatViewModel sendMessage:message];
    
}

- (void)chatBarFrameDidChange:(LCCKChatBar *)chatBar frame:(CGRect)frame{
    if (frame.origin.y == self.tableView.frame.size.height) {
        return;
    }
    [UIView animateWithDuration:.3f animations:^{
        [self.tableView setFrame:CGRectMake(0, 0, self.view.frame.size.width, frame.origin.y)];
        [self scrollToBottomAnimated:NO];
        
    } completion:nil];
}

#pragma mark - LCCKChatMessageCellDelegate

- (void)messageCellTappedHead:(LCCKChatMessageCell *)messageCell {
    LCCKOpenProfileBlock openProfileBlock = [LCCKUIService sharedInstance].openProfileBlock;
    !openProfileBlock ?: openProfileBlock(messageCell.message.sender, self);
    //    NSLog(@"tapHead :%@",indexPath);
}

- (void)messageCellTappedBlank:(LCCKChatMessageCell *)messageCell {
    [self.chatBar endInputing];
}

- (void)messageCellTappedMessage:(LCCKChatMessageCell *)messageCell {
    if (!messageCell) {
        return;
    }
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];
    LCCKMessage *message = [self.chatViewModel messageAtIndex:indexPath.row];
    switch (messageCell.messageType) {
        case LCCKMessageTypeVoice: {
            NSString *voiceFileName = message.voicePath;//1、必须带后缀，.mp3；FIXME:2、接收到的语音消息无法播放
            [[LCCKAVAudioPlayer sharePlayer] playAudioWithURLString:voiceFileName atIndex:indexPath.row];
        }
            break;
        case LCCKMessageTypeImage: {
            LCCKPreviewImageMessageBlock previewImageMessageBlock = [LCCKUIService sharedInstance].previewImageMessageBlock;
            NSDictionary *userInfo = @{
                                       LCCKPreviewImageMessageUserInfoKeyFromController : self,
                                       LCCKPreviewImageMessageUserInfoKeyFromView : self.tableView,
                                       };
            NSArray *imageMessages = nil;
            NSNumber *selectedMessageIndex = nil;
            [self.chatViewModel getAllImageMessagesForMessage:messageCell.message allImageMessageImages:&imageMessages selectedMessageIndex:&selectedMessageIndex];
            !previewImageMessageBlock ?: previewImageMessageBlock(selectedMessageIndex.unsignedIntegerValue, imageMessages, userInfo);
        }
            break;
        case LCCKMessageTypeLocation: {
            NSDictionary *userInfo = @{
                                       LCCKPreviewImageMessageUserInfoKeyFromController : self,
                                       LCCKPreviewImageMessageUserInfoKeyFromView : self.tableView,
                                       };
            LCCKPreviewLocationMessageBlock previewLocationMessageBlock = [LCCKUIService sharedInstance].previewLocationMessageBlock;
            !previewLocationMessageBlock ?: previewLocationMessageBlock(message.location, message.geolocations, userInfo);
        }
            break;
            
//        default:
//            break;
    }
}

- (void)textMessageCellDoubleTapped:(LCCKChatMessageCell *)messageCell {
    if (self.disableTextShowInFullScreen) {
        return;
    }
    LCCKTextFullScreenViewController *textFullScreenViewController = [[LCCKTextFullScreenViewController alloc] initWithText:messageCell.message.text];
    [self.navigationController pushViewController:textFullScreenViewController animated:NO];
}

- (void)messageCell:(LCCKChatMessageCell *)messageCell withActionType:(LCCKChatMessageCellMenuActionType)actionType {
    NSString *action = actionType ==LCCKChatMessageCellMenuActionTypeRelay ? @"转发" : @"复制";
    NSLog(@"messageCell :%@ willDoAction :%@",messageCell,action);
}

#pragma mark - LCCKConversationViewModelDelegate

- (NSString *)chatterNickname {
    return self.userId;
}

- (NSURL *)chatterHeadAvator {
    return self.avatorURL;
}

- (void)messageReadStateChanged:(LCCKMessageReadState)readState withProgress:(CGFloat)progress forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCCKChatMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![self.tableView.visibleCells containsObject:messageCell]) {
        return;
    }
    messageCell.messageReadState = readState;
}

- (void)messageSendStateChanged:(LCCKMessageSendState)sendState withProgress:(CGFloat)progress forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCCKChatMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![self.tableView.visibleCells containsObject:messageCell]) {
        return;
    }
    if (messageCell.messageType == LCCKMessageTypeImage) {
        [(LCCKChatImageMessageCell *)messageCell setUploadProgress:progress];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        messageCell.messageSendState = sendState;
    });
}

- (void)reloadAfterReceiveMessage:(LCCKMessage *)message {
    [self.tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatViewModel.messageCount - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

#pragma mark - LCCKAVAudioPlayerDelegate

- (void)audioPlayerStateDidChanged:(LCCKVoiceMessageState)audioPlayerState forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    //FIXME:Cell sometimes is textMessage
    LCCKChatVoiceMessageCell *voiceMessageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([voiceMessageCell respondsToSelector:@selector(setVoiceMessageState:)]) {
            [voiceMessageCell setVoiceMessageState:audioPlayerState];
        }
    });
}

- (void)loadMoreMessagesScrollTotop {
    [self.chatViewModel loadOldMessages];
}

- (void)updateStatusView {
    BOOL isConnected = [LCCKSessionService sharedInstance].connect;
    if (isConnected) {
        self.clientStatusView.hidden = YES;
    } else {
        self.clientStatusView.hidden = NO;
    }
}

@end
