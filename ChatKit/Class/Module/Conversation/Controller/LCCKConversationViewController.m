//
//  LCCKConversationViewController.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/20.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

//CYLDebugging定义为1表示【debugging】 ，注释、不定义或者0 表示【debugging】
//#define CYLDebugging 1


#import "LCCKConversationViewController.h"

#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif

#import "UITableView+FDTemplateLayoutCell.h"
#import "LCCKCellRegisterController.h"
#import "LCCKStatusView.h"
#import "LCCKSoundManager.h"
#import "LCCKTextFullScreenViewController.h"
#import <objc/runtime.h>
#import "NSMutableArray+LCCKMessageExtention.h"
#import "Masonry.h"

@interface LCCKConversationViewController () <LCCKChatBarDelegate, LCCKAVAudioPlayerDelegate, LCCKChatMessageCellDelegate, LCCKConversationViewModelDelegate>

@property (nonatomic, strong, readwrite) AVIMConversation *conversation;
//@property (copy, nonatomic) NSString *messageSender /**< 正在聊天的用户昵称 */;
//@property (copy, nonatomic) NSString *avatarURL /**< 正在聊天的用户头像 */;
/**< 正在聊天的用户 */
@property (nonatomic, copy) id<LCCKUserDelegate> user;
/**< 正在聊天的用户clientId */
@property (nonatomic, copy) NSString *userId;
/**< 正在聊天的用户头像 */
//@property (nonatomic, copy) NSURL *avatarURL;
@property (nonatomic, strong) LCCKConversationViewModel *chatViewModel;
@property (nonatomic, copy) LCCKConversationHandler conversationHandler;
@property (nonatomic, copy) LCCKViewControllerBooleanResultBlock loadHistoryMessagesHandler;

@end

@implementation LCCKConversationViewController

- (void)setConversationHandler:(LCCKConversationHandler)conversationHandler {
    _conversationHandler = conversationHandler;
}

- (void)setLoadHistoryMessagesHandler:(LCCKViewControllerBooleanResultBlock)loadHistoryMessagesHandler {
    _loadHistoryMessagesHandler = loadHistoryMessagesHandler;
}

#pragma mark -
#pragma mark - initialization Method

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _conversationId = [conversationId copy];
    [self setup];
    return self;
}

- (instancetype)initWithPeerId:(NSString *)peerId {
    self = [super init];
    if (!self) {
        return nil;
    }
    _peerId = [peerId copy];
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
    do {
        /* If object is clean, ignore save request. */
        if (_peerId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithPeerId:self.peerId callback:^(AVIMConversation *conversation, NSError *error) {
                [self refreshConversation:conversation isJoined:YES];
            }];
            break;
        }
        /* If object is clean, ignore save request. */
        if (_conversationId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithConversationId:self.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
                if (error) {
                    [self refreshConversation:conversation isJoined:NO];
                    return;
                }
                NSString *currentClientId = [LCCKSessionService sharedInstance].clientId;
                BOOL containsCurrentClientId = [conversation.members containsObject:currentClientId];
                if (containsCurrentClientId) {
                    [self refreshConversation:conversation isJoined:YES];
                    return;
                }
                [conversation joinWithCallback:^(BOOL succeeded, NSError *error) {
                    [self refreshConversation:conversation isJoined:succeeded];
                }];
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
        [self refreshConversation:nil isJoined:NO];
        LCCKSessionNotOpenedHandler sessionNotOpenedHandler = [LCCKSessionService sharedInstance].sessionNotOpenedHandler;
        LCCKBooleanResultBlock callback = ^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                //[self.navigationController popViewControllerAnimated:YES];
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
    self.view.backgroundColor = self.tableView.backgroundColor;
    [self.view addSubview:self.chatBar];
    [self.view addSubview:self.clientStatusView];
    [self updateStatusView];
    [self initBarButton];
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
        self.user = user;
    }];
    [self conversation];
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock(self);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self markCurrentConversationInfo];
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(self, animated);
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.conversationId) {
        [[LCCKConversationService sharedInstance] updateDraft:self.chatBar.cachedText conversationId:self.conversationId];
    }
    [[LCCKAVAudioPlayer sharePlayer] stopAudioPlayer];
    [LCCKAVAudioPlayer sharePlayer].index = NSUIntegerMax;
    [LCCKAVAudioPlayer sharePlayer].URLString = nil;
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(self, animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.chatViewModel.avimTypedMessage.count > 0) {
        [[LCCKConversationService sharedInstance] updateConversationAsRead];
    }
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(self, animated);
}

- (void)dealloc {
    [[LCCKAVAudioPlayer sharePlayer] setDelegate:nil];
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock(self);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(self, animated);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock(self);
}

#pragma mark - UI init

- (void)initBarButton {
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backBtn];
}

- (void)clearCurrentConversationInfo {
        [LCCKConversationService sharedInstance].currentConversationId = nil;
        [LCCKConversationService sharedInstance].currentConversation = nil;
}

- (void)markCurrentConversationInfo {
    if (self.conversationId) {
        [LCCKConversationService sharedInstance].currentConversationId = self.conversationId;
    } else if (self.conversation.conversationId) {
        [LCCKConversationService sharedInstance].currentConversationId = self.conversation.conversationId;
    }
    
    if (self.conversation) {
        [LCCKConversationService sharedInstance].currentConversation = self.conversation;
    }
}
/*!
 * conversation 不一定有值，可能为 nil，
 */
- (void)refreshConversation:(AVIMConversation *)conversation isJoined:(BOOL)isJoined {
    _conversation = conversation;
    if (conversation.members > 0) {
        NSAssert(_conversation.imClient, @"类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"imClient is nil");
        self.navigationItem.title = conversation.lcck_title;
        [[LCChatKit sharedInstance] getProfilesInBackgroundForUserIds:conversation.members callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            !_conversationHandler ?: _conversationHandler(conversation, self);
        }];
        if (self.conversation.lcck_draft.length > 0) {
            [self.chatBar appendString:self.conversation.lcck_draft];
        }
    } else {
        !_conversationHandler ?: _conversationHandler(conversation, self);
    }
    [self markCurrentConversationInfo];
    [LCCKConversationService sharedInstance].currentConversation = conversation;
    [self handleLoadHistoryMessagesHandlerForIsJoined:isJoined];
}

- (void)handleLoadHistoryMessagesHandlerForIsJoined:(BOOL)isJoined {
    if (!isJoined) {
        BOOL succeeded = NO;
        //错误码参考：https://leancloud.cn/docs/realtime_v2.html#服务器端错误码说明
        NSInteger code = 4312;
        NSString *errorReasonText = @"拉去对话消息记录被拒绝，当前用户不再对话中";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:@"kAVErrorDomain"
                                             code:code
                                         userInfo:errorInfo];
        
        !_loadHistoryMessagesHandler ?: _loadHistoryMessagesHandler(self, succeeded, error);
        return;
    }
    [self.chatViewModel loadMessagesFirstTimeWithHandler:^(BOOL succeeded, NSError *error) {
        !_loadHistoryMessagesHandler ?: _loadHistoryMessagesHandler(self, succeeded, error);
    }];
}

+ (NSTimeInterval)currentTimestamp {
    NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970];
    return seconds * 1000;
}

- (NSString *)userId {
    return [LCChatKit sharedInstance].clientId;
}

#pragma mark - LCCKChatBarDelegate

- (void)chatBar:(LCCKChatBar *)chatBar sendMessage:(NSString *)message {
    if ([message length] > 0 ) {
        LCCKMessage *lcckMessage = [[LCCKMessage alloc] initWithText:message
                                                              userId:self.userId
                                                              user:self.user
                                                           timestamp:[[self class] currentTimestamp]];
        lcckMessage.messageGroupType = self.conversation.lcck_type;
        [self.chatViewModel sendMessage:lcckMessage];
    }
}

- (void)chatBar:(LCCKChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    [self sendVoiceWithPath:voiceFileName seconds:seconds];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendPictures:(NSArray<UIImage *> *)pictures{
    [self sendImages:pictures];
}

- (void)didInputAtSign:(LCCKChatBar *)chatBar {
    if (self.conversation.lcck_type == LCCKConversationTypeGroup) {
        [self presentSelectMemberViewController];
    }
}

- (void)presentSelectMemberViewController {
   NSString *cuttentClientId = [LCCKSessionService sharedInstance].clientId;
    [[LCCKUserSystemService sharedInstance] getProfilesInBackgroundForUserIds:self.conversation.members callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
        LCCKContactListViewController *contactListViewController = [[LCCKContactListViewController alloc] initWithContacts:users userIds:self.conversation.members excludedUserIds:@[cuttentClientId] mode:LCCKContactListModeMultipleSelection];
        [contactListViewController setSelectedContactCallback:^(UIViewController *viewController, NSString *peerId) {
//            [viewController dismissViewControllerAnimated:YES completion:nil];
            if (peerId.length > 0) {
               NSArray *peerNames = [[LCChatKit sharedInstance] getProfilesForUserIds:@[peerId] error:nil];
                NSString *peerName;
                @try {
                    id<LCCKUserDelegate> user = peerNames[0];
                    peerName = [NSString stringWithFormat:@"%@ ",user.name];
                } @catch (NSException *exception) {
                    peerName = [NSString stringWithFormat:@"%@ ", peerId];
                }
                [self.chatBar appendString:[NSString stringWithFormat:@"%@ ",peerName]];
            }
        }];
        [contactListViewController setSelectedContactsCallback:^(UIViewController *viewController, NSArray<NSString *> *peerIds) {
            if (peerIds.count > 0) {
                NSArray<id<LCCKUserDelegate>> *peers = [[LCChatKit sharedInstance] getProfilesForUserIds:peerIds error:nil];
                NSMutableArray *peerNames = [NSMutableArray arrayWithCapacity:peers.count];
                [peers enumerateObjectsUsingBlock:^(id<LCCKUserDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.name) {
                        [peerNames addObject:obj.name];
                    } else {
                        [peerNames addObject:obj.clientId];
                    }
                }];
                NSString *peerName;
                if (peerNames.count > 0) {
                    peerName = [[peerNames valueForKey:@"description"] componentsJoinedByString:@" @"];
                } else {
                    peerName = [[peerIds valueForKey:@"description"] componentsJoinedByString:@" @"];
                }
                peerName = [peerName stringByAppendingString:@" "];
                [self.chatBar appendString:peerName];
            }
        }];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contactListViewController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }];
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
                                                           userId:self.userId
                                                           user:self.user
                                                        timestamp:[[self class] currentTimestamp]];
        message.messageGroupType = self.conversation.lcck_type;
        [self.chatViewModel sendMessage:message];
    } else {
        [self alert:@"write image to file error"];
    }
}

- (void)sendVoiceWithPath:(NSString *)voicePath seconds:(NSTimeInterval)seconds {
    LCCKMessage *message = [[LCCKMessage alloc] initWithVoicePath:voicePath
                                                         voiceURL:nil
                                                    voiceDuration:[NSString stringWithFormat:@"%@", @(seconds)]
                                                           userId:self.userId
                                                           user:self.user
                                                        timestamp:[[self class] currentTimestamp]];
    message.messageGroupType =  self.conversation.lcck_type;
    [self.chatViewModel sendMessage:message];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText{
    LCCKMessage *message = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
        NSString *imageName = @"message_sender_location";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
        image;})
                                                              geolocations:locationText
                                                                  location:[[CLLocation alloc] initWithLatitude:locationCoordinate.latitude
                                                                                                      longitude:locationCoordinate.longitude]
                                                                    userId:self.userId
                                                                    user:self.user
                                                                 timestamp:[[self class] currentTimestamp]];
    [self.chatViewModel sendMessage:message];
}

- (void)chatBarFrameDidChange:(LCCKChatBar *)chatBar {
    [UIView animateWithDuration:LCCKAnimateDuration animations:^{
        [self.tableView layoutIfNeeded];
        [self scrollToBottomAnimated:NO];
    } completion:nil];
}

#pragma mark - LCCKChatMessageCellDelegate

- (void)messageCellTappedHead:(LCCKChatMessageCell *)messageCell {
    LCCKOpenProfileBlock openProfileBlock = [LCCKUIService sharedInstance].openProfileBlock;
    !openProfileBlock ?: openProfileBlock(messageCell.message.userId, messageCell.message.user, self);
}

- (void)messageCellTappedBlank:(LCCKChatMessageCell *)messageCell {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (void)messageCellTappedMessage:(LCCKChatMessageCell *)messageCell {
    if (!messageCell) {
        return;
    }
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];
    LCCKMessage *message = [self.chatViewModel.dataArray lcck_messageAtIndex:indexPath.row];
    switch (messageCell.messageType) {
        case LCCKMessageTypeVoice: {
            NSString *voiceFileName = message.voicePath;//1、必须带后缀，.mp3；FIXME:2、接收到的语音消息无法播放
            [[LCCKAVAudioPlayer sharePlayer] playAudioWithURLString:voiceFileName atIndex:indexPath.row];
        }
            break;
        case LCCKMessageTypeImage: {
            LCCKPreviewImageMessageBlock previewImageMessageBlock = [LCCKUIService sharedInstance].previewImageMessageBlock;
            NSDictionary *userInfo = @{
                                       /// 传递触发的UIViewController对象
                                       LCCKPreviewImageMessageUserInfoKeyFromController : self,
                                       /// 传递触发的UIView对象
                                       LCCKPreviewImageMessageUserInfoKeyFromView : self.tableView,
                                       };
            NSArray *allVisibleImages = nil;
            NSArray *allVisibleThumbs = nil;
            NSNumber *selectedMessageIndex = nil;
            [self.chatViewModel getAllVisibleImagesForSelectedMessage:messageCell.message allVisibleImages:&allVisibleImages allVisibleThumbs:&allVisibleThumbs selectedMessageIndex:&selectedMessageIndex];
            !previewImageMessageBlock ?: previewImageMessageBlock(selectedMessageIndex.unsignedIntegerValue, allVisibleImages, allVisibleThumbs, userInfo);
        }
            break;
        case LCCKMessageTypeLocation: {
            NSDictionary *userInfo = @{
                                       /// 传递触发的UIViewController对象
                                       LCCKPreviewLocationMessageUserInfoKeyFromController : self,
                                       /// 传递触发的UIView对象
                                       LCCKPreviewLocationMessageUserInfoKeyFromView : self.tableView,
                                       };
            LCCKPreviewLocationMessageBlock previewLocationMessageBlock = [LCCKUIService sharedInstance].previewLocationMessageBlock;
            !previewLocationMessageBlock ?: previewLocationMessageBlock(message.location, message.geolocations, userInfo);
        }
            break;
        case LCCKMessageTypeText:
            break;
        default: {
            NSString *formatString = @"\n\n\
            ------ BEGIN NSException Log ---------------\n \
            class name: %@                              \n \
            ------line: %@                              \n \
            ----reason: %@                              \n \
            ------ END -------------------------------- \n\n";
            NSString *reason = [NSString stringWithFormat:formatString,
                                @(__PRETTY_FUNCTION__),
                                @(__LINE__),
                                @"messageCell.messageType not handled"];
            //手动创建一个异常导致的崩溃事件 http://is.gd/EfVfN0
            @throw [NSException exceptionWithName:NSGenericException
                                           reason:reason
                                         userInfo:nil];
        }
                        break;
    }
}

- (void)avatarImageViewLongPressed:(LCCKChatMessageCell *)messageCell {
    NSString *userName = messageCell.message.user.name ?: messageCell.message.userId;
    NSString *appendString = [NSString stringWithFormat:@"@%@ ", userName];
    [self.chatBar appendString:appendString];
}

- (void)textMessageCellDoubleTapped:(LCCKChatMessageCell *)messageCell {
    if (self.disableTextShowInFullScreen) {
        return;
    }
    LCCKTextFullScreenViewController *textFullScreenViewController = [[LCCKTextFullScreenViewController alloc] initWithText:messageCell.message.text];
    [self.navigationController pushViewController:textFullScreenViewController animated:NO];
}

- (void)resendMessage:(LCCKChatMessageCell *)messageCell {
    [self.chatViewModel resendMessageForMessageCell:messageCell];
}

#pragma mark - LCCKConversationViewModelDelegate

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
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
