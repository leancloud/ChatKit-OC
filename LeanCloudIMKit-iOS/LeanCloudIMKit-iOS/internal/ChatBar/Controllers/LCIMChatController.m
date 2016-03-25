//
//  LCIMChatController.m
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

//CYLDebugging定义为1表示【debugging】 ，注释、不定义或者0 表示【debugging】
//#define CYLDebugging 1

#import "LCIMChatController.h"
#import "UITableView+FDTemplateLayoutCell.h"
#import "LCIMCellRegisterController.h"
#import <AVOSCloudIM/AVOSCloudIM.h>
#import "LCIMConversationService.h"
#import "LCIMUserSystemService.h"
#import "AVIMConversation+LCIMAddition.h"
#import "LCIMStatusView.h"
#import "LCIMSessionService.h"
#import "XHAudioPlayerHelper.h"
#import "LCIMConversationService.h"
#import "LCIMSettingService.h"
#import "LCIMEmotionUtils.h"
#import "LCIMSoundManager.h"
#import "LCIMTextFullScreenViewController.h"

#define kSelfName @"https://LeanCloud.cn "
#define kSelfThumb @"http://img1.touxiang.cn/uploads/20131114/14-065809_117.jpg"

@interface LCIMChatController () <LCIMChatBarDelegate, LCIMAVAudioPlayerDelegate, LCIMChatMessageCellDelegate, LCIMChatViewModelDelegate>

@property (nonatomic, strong, readwrite) AVIMConversation *conversation;
//@property (copy, nonatomic) NSString *messageSender /**< 正在聊天的用户昵称 */;
//@property (copy, nonatomic) NSString *chatterThumb /**< 正在聊天的用户头像 */;
@property (nonatomic, strong) LCIMStatusView *clientStatusView;
@property (assign, nonatomic) LCIMMessageChat messageChatType;
/**< 正在聊天的用户昵称 */
@property (nonatomic, copy) NSString *chatterName;
 /**< 正在聊天的用户头像 */
@property (nonatomic, copy) NSURL *chatterThumb;
//@property (assign, nonatomic) LCIMMessageChat messageChatType;
@property (nonatomic, strong) LCIMChatViewModel *chatViewModel;

@end

@implementation LCIMChatController

//- (instancetype)initWithChatType:(LCIMMessageChat)messageChatType{
//    if ([super init]) {
//        _messageChatType = messageChatType;
//    }
//    return self;
//}

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

//- (instancetype)initWithConversation:(AVIMConversation *)conversation {
//    self = [super init];
//    if (!self) {
//        return nil;
//    }
//    [self setup];
//    _conversation = conversation;
//    [self refreshConversation:conversation];
//    return self;
//}

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
            if (_conversationId) {
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

#pragma mark - Life Cycle

- (void)setup {
    self.loadingMoreMessage = NO;
    self.disableTextShowInFullScreen = NO;
}

/**
 *  lazy load chatViewModel
 *
 *  @return LCIMChatViewModel
 */
- (LCIMChatViewModel *)chatViewModel {
    if (_chatViewModel == nil) {
        LCIMChatViewModel *chatViewModel = [[LCIMChatViewModel alloc] initWithparentViewController:self];
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
    [LCIMAVAudioPlayer sharePlayer].delegate = self;
    self.view.backgroundColor = [UIColor colorWithRed:234.0f/255.0f green:234/255.0f blue:234/255.f alpha:1.0f];
    [self.view addSubview:self.chatBar];
    [self initBarButton];
    [self.view addSubview:self.clientStatusView];
    [self updateStatusView];

    [[LCIMUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCIMUserModelDelegate> user, NSError *error) {
        // 设置自身用户名
        self.chatterName = user.name;
        self.chatterThumb = user.avatorURL;
    }];
    [LCIMConversationService sharedInstance].chattingConversationId = self.conversation.conversationId;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [LCIMConversationService sharedInstance].chattingConversationId = self.conversation.conversationId;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[LCIMAVAudioPlayer sharePlayer] stopAudioPlayer];
    [LCIMAVAudioPlayer sharePlayer].index = NSUIntegerMax;
    [LCIMAVAudioPlayer sharePlayer].URLString = nil;
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [LCIMConversationService sharedInstance].chattingConversationId = nil;
    if (self.chatViewModel.avimTypedMessage.count > 0) {
        [self.chatViewModel updateConversationAsRead];
    }
    [[XHAudioPlayerHelper shareInstance] stopAudio];
}

- (void)dealloc {
    [[XHAudioPlayerHelper shareInstance] setDelegate:nil];
}

#pragma mark - ui init

- (void)initBarButton {
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backBtn];
}

#pragma mark - connect status view

- (LCIMStatusView *)clientStatusView {
    if (_clientStatusView == nil) {
        _clientStatusView = [[LCIMStatusView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, LCIMStatusViewHight)];
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

- (void)refreshConversation:(AVIMConversation *)conversation {
    _conversation = conversation;
    self.navigationItem.title = conversation.lcim_title;
    [LCIMConversationService sharedInstance].currentConversation = conversation;;
    [self.chatViewModel loadMessagesWhenInit];
}

#pragma mark - LCIMChatBarDelegate

- (void)chatBar:(LCIMChatBar *)chatBar sendMessage:(NSString *)message {
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    if ([message length] > 0 ) {
        LCIMMessage *lcimMessage = [[LCIMMessage alloc] initWithText:message
                                                              sender:[LCIMKit sharedInstance].clientId
                                                           timestamp:[NSDate date]];
        //TODO:
        lcimMessage.messageGroupType = LCIMMessageChatSingle;
        [self.chatViewModel sendMessage:lcimMessage];
    }
}

- (void)chatBar:(LCIMChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
        return;
    }
    [self sendVoiceWithPath:voiceFileName];
}

- (void)chatBar:(LCIMChatBar *)chatBar sendPictures:(NSArray<UIImage *> *)pictures{
    if ([LCIMSessionService sharedInstance].client.status != AVIMClientStatusOpened) {
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
    NSString *path = [[LCIMSettingService sharedInstance] tmpPath];
    NSError *error;
    [imageData writeToFile:path options:NSDataWritingAtomic error:&error];
    if (error == nil) {
        LCIMMessage *message = [[LCIMMessage alloc] initWithPhoto:image
                                                        photoPath:path
                                                     thumbnailURL:nil
                                                   originPhotoURL:nil
                                                           sender:[LCIMKit sharedInstance].clientId
                                                        timestamp:[NSDate date]];
        //TODO:
        message.messageGroupType = LCIMMessageChatSingle;
        [self.chatViewModel sendMessage:message];
    } else {
        [self alert:@"write image to file error"];
    }
}

- (void)sendVoiceWithPath:(NSString *)voicePath {
    LCIMMessage *message = [[LCIMMessage alloc] initWithVoicePath:voicePath
                                                     voiceURL:nil
                                                voiceDuration:nil
                                                       sender:[LCIMKit sharedInstance].clientId
                                                    timestamp:[NSDate date]];
    //TODO:
    message.messageGroupType = LCIMMessageChatSingle;
    [self.chatViewModel sendMessage:message];
}

- (void)chatBar:(LCIMChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText{
//TODO:
//    NSMutableDictionary *locationMessageDict = [NSMutableDictionary dictionary];
//    locationMessageDict[kLCIMMessageConfigurationTypeKey] = @(LCIMMessageTypeLocation);
//    locationMessageDict[kLCIMMessageConfigurationOwnerKey] = @(LCIMMessageOwnerSelf);
//    locationMessageDict[kLCIMMessageConfigurationGroupKey] = @(self.messageChatType);
//    locationMessageDict[kLCIMMessageConfigurationNicknameKey] = kSelfName;
//    locationMessageDict[kLCIMMessageConfigurationAvatarKey] = kSelfThumb;
//    locationMessageDict[kLCIMMessageConfigurationLocationKey]=locationText;
//    [self addMessage:locationMessageDict];
}

- (void)chatBarFrameDidChange:(LCIMChatBar *)chatBar frame:(CGRect)frame{
    if (frame.origin.y == self.tableView.frame.size.height) {
        return;
    }
    [UIView animateWithDuration:.3f animations:^{
        [self.tableView setFrame:CGRectMake(0, 0, self.view.frame.size.width, frame.origin.y)];
    } completion:nil];
}

#pragma mark - LCIMChatMessageCellDelegate

- (void)messageCellTappedHead:(LCIMChatMessageCell *)messageCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];
    LCIMOpenProfileBlock openProfileBlock = [LCIMUIService sharedInstance].openProfileBlock;
    !openProfileBlock ?: openProfileBlock(messageCell.message.sender, self);
    NSLog(@"tapHead :%@",indexPath);
}

- (void)messageCellTappedBlank:(LCIMChatMessageCell *)messageCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];
    NSLog(@"tapBlank :%@",indexPath);
    [self.chatBar endInputing];
}

- (void)messageCellTappedMessage:(LCIMChatMessageCell *)messageCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];

    NSLog(@"tapMessage :%@",indexPath);
    switch (messageCell.messageType) {
        case LCIMMessageTypeVoice:
        {
            LCIMMessage *message = [self.chatViewModel messageAtIndex:indexPath.row];
            NSString *voiceFileName = message.voicePath;
            [[LCIMAVAudioPlayer sharePlayer] playAudioWithURLString:voiceFileName atIndex:indexPath.row];
        }
            break;
        case LCIMMessageTypeImage:
        {
            LCIMPreviewImageMessageBlock previewImageMessageBlock = [LCIMUIService sharedInstance].previewImageMessageBlock;
            NSDictionary *userInfo = @{
                                       LCIMPreviewImageMessageUserInfoKeyFromController : self,
                                       LCIMPreviewImageMessageUserInfoKeyFromView : self.tableView,
                                       };
            NSArray *imageMessages = nil;
            NSNumber *selectedMessageIndex = nil;
            [self.chatViewModel getAllImageMessagesForMessage:messageCell.message allImageMessageImages:&imageMessages selectedMessageIndex:&selectedMessageIndex];
            !previewImageMessageBlock ?: previewImageMessageBlock(selectedMessageIndex.unsignedIntegerValue, imageMessages, userInfo);
        }
            break;
            //TODO:
    }
}

- (void)textMessageCellDoubleTapped:(LCIMChatMessageCell *)messageCell {
    if (self.disableTextShowInFullScreen) {
        return;
    }
    LCIMTextFullScreenViewController *textFullScreenViewController = [[LCIMTextFullScreenViewController alloc] initWithText:messageCell.message.text];
    [self.navigationController pushViewController:textFullScreenViewController animated:NO];
}

- (void)messageCell:(LCIMChatMessageCell *)messageCell withActionType:(LCIMChatMessageCellMenuActionType)actionType {
    NSString *action = actionType ==LCIMChatMessageCellMenuActionTypeRelay ? @"转发" : @"复制";
    NSLog(@"messageCell :%@ willDoAction :%@",messageCell,action);
}

#pragma mark - LCIMChatViewModelDelegate

- (NSString *)chatterNickname {
    return self.chatterName;
}

- (NSURL *)chatterHeadAvator {
    return self.chatterThumb;
}

- (void)messageReadStateChanged:(LCIMMessageReadState)readState withProgress:(CGFloat)progress forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCIMChatMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![self.tableView.visibleCells containsObject:messageCell]) {
        return;
    }
    messageCell.messageReadState = readState;
}

- (void)messageSendStateChanged:(LCIMMessageSendState)sendState withProgress:(CGFloat)progress forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCIMChatMessageCell *messageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![self.tableView.visibleCells containsObject:messageCell]) {
        return;
    }
    if (messageCell.messageType == LCIMMessageTypeImage) {
        [(LCIMChatImageMessageCell *)messageCell setUploadProgress:progress];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        messageCell.messageSendState = sendState;
    });
}

- (void)reloadAfterReceiveMessage:(LCIMMessage *)message {
    [self.tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.chatViewModel.messageCount - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

#pragma mark - LCIMAVAudioPlayerDelegate

- (void)audioPlayerStateDidChanged:(LCIMVoiceMessageState)audioPlayerState forIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    LCIMChatVoiceMessageCell *voiceMessageCell = [self.tableView cellForRowAtIndexPath:indexPath];
    dispatch_async(dispatch_get_main_queue(), ^{
        [voiceMessageCell setVoiceMessageState:audioPlayerState];
    });
}

- (void)loadMoreMessagesScrollTotop {
    [self.chatViewModel loadOldMessages];
}

@end
