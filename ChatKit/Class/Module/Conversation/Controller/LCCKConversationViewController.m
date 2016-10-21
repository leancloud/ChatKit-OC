//
//  LCCKConversationViewController.m
//  LCCKChatBarExample
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/20.
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
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
#import "LCCKConversationNavigationTitleView.h"
#import "LCCKWebViewController.h"
#import "LCCKSafariActivity.h"
#import "LCCKAlertController.h"
#import "LCCKPhotoBrowser.h"

#ifdef CYLDebugging
#import <MLeaksFinder/MLeaksFinder.h>
#endif

NSString *const LCCKConversationViewControllerErrorDomain = @"LCCKConversationViewControllerErrorDomain";

@interface LCCKConversationViewController () <LCCKChatBarDelegate, LCCKChatMessageCellDelegate, LCCKConversationViewModelDelegate, LCCKPhotoBrowserDelegate>

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
@property (nonatomic, copy) LCCKFetchConversationHandler fetchConversationHandler;
@property (nonatomic, copy) LCCKLoadLatestMessagesHandler loadLatestMessagesHandler;
@property (nonatomic, copy, readwrite) NSString *conversationId;
@property (nonatomic, strong) LCCKWebViewController *webViewController;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, assign, getter=isFirstTimeJoinGroup) BOOL firstTimeJoinGroup;

@end

@implementation LCCKConversationViewController

- (void)setFetchConversationHandler:(LCCKFetchConversationHandler)fetchConversationHandler {
    _fetchConversationHandler = fetchConversationHandler;
}

- (void)setLoadLatestMessagesHandler:(LCCKLoadLatestMessagesHandler)loadLatestMessagesHandler {
    _loadLatestMessagesHandler = loadLatestMessagesHandler;
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

- (AVIMConversation *)getConversationIfExists {
    if (_conversation) {
        return _conversation;
    }
    return nil;
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
                //SDK没有好友观念，任何两个ID均可会话，请APP层自行处理好友关系。
                [self refreshConversation:conversation isJoined:YES error:error];
            }];
            break;
        }
        /* If object is clean, ignore save request. */
        if (_conversationId) {
            [[LCCKConversationService sharedInstance] fecthConversationWithConversationId:self.conversationId callback:^(AVIMConversation *conversation, NSError *error) {
                if (error) {
                    //如果用户已经已经被踢出群，此时依然能拿到 Conversation 对象，不会报 4401 错误，需要单独判断。即使后期服务端在这种情况下返回error，这里依然能正确处理。
                    [self refreshConversation:conversation isJoined:NO error:error];
                    return;
                }
                NSString *currentClientId = [LCCKSessionService sharedInstance].clientId;
                //系统对话无成员概念，对应字段的优先顺序 sys > tr > memeber
                if (conversation.members.count == 0 && (!conversation.transient)) {
                    [self refreshConversation:conversation isJoined:YES];
                    return;
                }
                BOOL containsCurrentClientId = [conversation.members containsObject:currentClientId];
                if (containsCurrentClientId) {
                    [self refreshConversation:conversation isJoined:YES];
                    return;
                }
                if (self.isEnableAutoJoin) {
                    [conversation joinWithCallback:^(BOOL succeeded, NSError *error) {
                        [self refreshConversation:conversation isJoined:succeeded error:error];
                        if (succeeded) {
                            self.firstTimeJoinGroup = YES;
                        }
                    }];
                } else {
                    NSInteger code = 4401;
                    //错误码参考：https://leancloud.cn/docs/realtime_v2.html#%E4%BA%91%E7%AB%AF%E9%94%99%E8%AF%AF%E7%A0%81%E8%AF%B4%E6%98%8E
                    NSString *errorReasonText = @"INVALID_MESSAGING_TARGET 您已被被管理员移除该群";
                    NSDictionary *errorInfo = @{
                                                @"code":@(code),
                                                NSLocalizedDescriptionKey : errorReasonText,
                                                };
                    NSError *error_ = [NSError errorWithDomain:NSStringFromClass([self class])
                                                          code:code
                                                      userInfo:errorInfo];
                    [self refreshConversation:conversation isJoined:NO error:error_];
                }
            }];
            break;
        }
    } while (NO);
    return _conversation;
}

#pragma mark - Life Cycle

- (void)setup {
    self.allowScrollToBottom = YES;
    self.loadingMoreMessage = NO;
    self.disableTextShowInFullScreen = NO;
    BOOL clientStatusOpened = [LCCKSessionService sharedInstance].client.status == AVIMClientStatusOpened;
    //    NSAssert(clientStatusOpened, @"client not opened");
    if (!clientStatusOpened) {
        [self refreshConversation:nil isJoined:NO];
        [[LCCKSessionService sharedInstance] reconnectForViewController:self callback:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self conversation];
            }
        }];
    }
}

#ifdef CYLDebugging
- (BOOL)willDealloc {
    if (![super willDealloc]) {
        return NO;
    }
    MLCheck(self.chatViewModel);
    return YES;
}
#endif


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
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan = NO;
    self.tableView.delegate = self.chatViewModel;
    self.tableView.dataSource = self.chatViewModel;
    self.chatBar.delegate = self;
    [self.view addSubview:self.chatBar];
    [self.view addSubview:self.clientStatusView];
    [self updateStatusView];
    [self initBarButton];
    [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
        self.user = user;
    }];
    [self.chatViewModel setDefaultBackgroundImage];
    self.navigationItem.title = @"聊天";
    !self.viewDidLoadBlock ?: self.viewDidLoadBlock(self);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self conversation];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(self, animated);
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.chatBar open];
    [self saveCurrentConversationInfoIfExists];
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(self, animated);
}

- (void)loadDraft {
    [self.chatBar appendString:_conversation.lcck_draft];
    [self.chatBar beginInputing];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self.chatBar close];
    NSString *conversationId = [self getConversationIdIfExists:nil];
    if (conversationId) {
        [[LCCKConversationService sharedInstance] updateDraft:self.chatBar.cachedText conversationId:conversationId];
    }
    [self clearCurrentConversationInfo];
    [[LCCKAVAudioPlayer sharePlayer] stopAudioPlayer];
    [LCCKAVAudioPlayer sharePlayer].identifier = nil;
    [LCCKAVAudioPlayer sharePlayer].URLString = nil;
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(self, animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_conversation && (self.chatViewModel.avimTypedMessage.count > 0)) {
        [[LCCKConversationService sharedInstance] updateConversationAsRead];
    }
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(self, animated);
}

- (void)dealloc {
    _chatViewModel.delegate = nil;
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock(self);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock(self);
}

#pragma mark -
#pragma mark - public Methods

- (void)sendTextMessage:(NSString *)text {
    if ([text length] > 0 ) {
        LCCKMessage *lcckMessage = [[LCCKMessage alloc] initWithText:text
                                                            senderId:self.userId
                                                              sender:self.user
                                                           timestamp:LCCK_CURRENT_TIMESTAMP
                                                     serverMessageId:nil];
        [self makeSureSendValidMessage:lcckMessage afterFetchedConversationShouldWithAssert:NO];
        [self.chatViewModel sendMessage:lcckMessage];
    }
}

- (void)sendImages:(NSArray<UIImage *> *)pictures {
    for (UIImage *image in pictures) {
        [self sendImageMessage:image];
    }
}

- (void)sendImageMessage:(UIImage *)image {
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    [self sendImageMessageData:imageData];
}

- (void)sendImageMessageData:(NSData *)imageData {
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
                                                         senderId:self.userId
                                                           sender:self.user
                                                        timestamp:LCCK_CURRENT_TIMESTAMP
                                                  serverMessageId:nil
                                ];
        [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
        [self.chatViewModel sendMessage:message];
    } else {
        [self alert:@"write image to file error"];
    }
}

- (void)sendVoiceMessageWithPath:(NSString *)voicePath time:(NSTimeInterval)recordingSeconds {

    LCCKMessage *message = [[LCCKMessage alloc] initWithVoicePath:voicePath
                                                         voiceURL:nil
                                                    voiceDuration:[NSString stringWithFormat:@"%@", @(recordingSeconds)]
                                                         senderId:self.userId
                                                           sender:self.user
                                                        timestamp:LCCK_CURRENT_TIMESTAMP
                                                  serverMessageId:nil];
    [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
    [self.chatViewModel sendMessage:message];
}

- (void)sendLocationMessageWithLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate locatioTitle:(NSString *)locationTitle {

    LCCKMessage *message = [[LCCKMessage alloc] initWithLocalPositionPhoto:({
        NSString *imageName = @"message_sender_location";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
        image;})
                                                              geolocations:locationTitle
                                                                  location:[[CLLocation alloc] initWithLatitude:locationCoordinate.latitude
                                                                                                      longitude:locationCoordinate.longitude]
                                                                  senderId:self.userId
                                                                    sender:self.user
                                                                 timestamp:LCCK_CURRENT_TIMESTAMP
                                                           serverMessageId:nil];
    [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:NO];
    [self.chatViewModel sendMessage:message];
}

- (void)sendLocalFeedbackTextMessge:(NSString *)localFeedbackTextMessge {
    [self.chatViewModel sendLocalFeedbackTextMessge:localFeedbackTextMessge];
}

- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage {
    [self makeSureSendValidMessageAfterFetchedConversation:customMessage];
    [self.chatViewModel sendCustomMessage:customMessage];
}

- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage
            progressBlock:(AVProgressBlock)progressBlock
                  success:(LCCKBooleanResultBlock)success
                   failed:(LCCKBooleanResultBlock)failed {
    [self makeSureSendValidMessageAfterFetchedConversation:customMessage];
    [self.chatViewModel sendCustomMessage:customMessage progressBlock:progressBlock success:success failed:failed];
}

- (void)makeSureSendValidMessageAfterFetchedConversation:(id)message {
    [self makeSureSendValidMessage:message afterFetchedConversationShouldWithAssert:YES];
}

- (void)makeSureSendValidMessage:(id)message afterFetchedConversationShouldWithAssert:(BOOL)withAssert {
    NSString *formatString = @"\n\n\
    ------ BEGIN NSException Log ---------------\n \
    class name: %@                              \n \
    ------line: %@                              \n \
    ----reason: %@                              \n \
    ------ END -------------------------------- \n\n";
    if (!self.isAvailable) {
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__),
                            @"Remember to check if `isAvailable` is ture, making sure sending message after conversation has been fetched"];
        if (!withAssert) {
            LCCKLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), reason);
            return;
        }
        NSAssert(NO, reason);
    }
    if ([message isKindOfClass:[LCCKMessage class]]) {
        return;
    }
    if ([message isKindOfClass:[AVIMTypedMessage class]]) {
        return;
    }
    if ([[message class] isSubclassOfClass:[AVIMMessage class]]) {
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__),
                            @"ChatKit only support sending AVIMTypedMessage"];
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
    }
}

#pragma mark - UI init

- (void)initBarButton {
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backBtn];
}

- (void)clearCurrentConversationInfo {
    [LCCKConversationService sharedInstance].currentConversationId = nil;
}

- (void)saveCurrentConversationInfoIfExists {
    NSString *conversationId = [self getConversationIdIfExists:nil];
    if (conversationId) {
        [LCCKConversationService sharedInstance].currentConversationId = conversationId;
    }
    
    if (_conversation) {
        [LCCKConversationService sharedInstance].currentConversation = self.conversation;
    }
}

- (void)setupNavigationItemTitleWithConversation:(AVIMConversation *)conversation {
    LCCKConversationNavigationTitleView *navigationItemTitle = [[LCCKConversationNavigationTitleView alloc] initWithConversation:conversation navigationController:self.navigationController];
    navigationItemTitle.frame = CGRectZero;
    //仅修高度,xyw值不变
    navigationItemTitle.frame = ({
        CGRect frame = navigationItemTitle.frame;
        CGFloat containerViewHeight = self.navigationController.navigationBar.frame.size.height;
        CGFloat containerViewWidth = self.navigationController.navigationBar.frame.size.width - 130;
        frame.size.width = containerViewWidth;
        frame.size.height = containerViewHeight;
        frame;
    });
    self.navigationItem.titleView = navigationItemTitle;
}

- (void)fetchConversationHandler:(AVIMConversation *)conversation {
    LCCKFetchConversationHandler fetchConversationHandler;
    do {
        if (_fetchConversationHandler) {
            fetchConversationHandler = _fetchConversationHandler;
            break;
        }
        LCCKFetchConversationHandler generalFetchConversationHandler = [LCCKConversationService sharedInstance].fetchConversationHandler;
        if (generalFetchConversationHandler) {
            fetchConversationHandler = generalFetchConversationHandler;
            break;
        }
    } while (NO);
    if (fetchConversationHandler) {
        dispatch_async(dispatch_get_main_queue(),^{
            fetchConversationHandler(conversation, self);
        });
    }
}

- (void)loadLatestMessagesHandler:(BOOL)succeeded error:(NSError *)error {
    LCCKLoadLatestMessagesHandler loadLatestMessagesHandler;
    do {
        if (_loadLatestMessagesHandler) {
            loadLatestMessagesHandler = _loadLatestMessagesHandler;
            break;
        }
        LCCKLoadLatestMessagesHandler generalLoadLatestMessagesHandler = [LCCKConversationService sharedInstance].loadLatestMessagesHandler;
        if (generalLoadLatestMessagesHandler) {
            loadLatestMessagesHandler = generalLoadLatestMessagesHandler;
            break;
        }
    } while (NO);
    if (loadLatestMessagesHandler) {
        dispatch_async(dispatch_get_main_queue(),^{
            loadLatestMessagesHandler(self, succeeded, error);
        });
    }
}

- (void)refreshConversation:(AVIMConversation *)conversation isJoined:(BOOL)isJoined {
    [self refreshConversation:conversation isJoined:isJoined error:nil];
}

- (NSString *)getConversationIdIfExists:(AVIMConversation *)conversation {
    NSString *conversationId;
    do {
        if (self.conversationId) {
            conversationId = self.conversationId;
            break;
        }
        if (_conversation) {
            conversationId = self.conversation.conversationId;
            break;
        }
        if (conversation) {
            conversationId = conversation.conversationId;
            break;
        }
    } while (NO);
    return conversationId;
}

- (void)notJoinedHandler:(AVIMConversation *)conversation error:(NSError *)aError {
    void(^notJoinedHandler)(id<LCCKUserDelegate> user, NSError *error) = ^(id<LCCKUserDelegate> user, NSError *error) {
        LCCKConversationInvalidedHandler conversationInvalidedHandler = [[LCCKConversationService sharedInstance] conversationInvalidedHandler];
        NSString *conversationId = [self getConversationIdIfExists:conversation];
        //错误码参考：https://leancloud.cn/docs/realtime_v2.html#%E4%BA%91%E7%AB%AF%E9%94%99%E8%AF%AF%E7%A0%81%E8%AF%B4%E6%98%8E
        if (error.code == 4401 && conversationId.length > 0) {
            //如果被管理员踢出群之后，再进入该会话，本地可能有缓存，要清除掉，防止下次再次进入。
            [[LCCKConversationService sharedInstance] deleteRecentConversationWithConversationId:conversationId];
        }
        conversationInvalidedHandler(conversationId, self, user, error);
    };
    
    if (conversation && (conversation.creator.length > 0)) {
        [[LCCKUserSystemService sharedInstance] getProfilesInBackgroundForUserIds:@[ conversation.creator ] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            id<LCCKUserDelegate> user;
            @try {
                user = users[0];
            } @catch (NSException *exception) {}
            !notJoinedHandler ?: notJoinedHandler(user, aError);
        }];
    } else {
        !notJoinedHandler ?: notJoinedHandler(nil, aError);
    }
}

/*!
 * conversation 不一定有值，可能为 nil
 */
- (void)refreshConversation:(AVIMConversation *)aConversation isJoined:(BOOL)isJoined error:(NSError *)error {
    if (error) {
        [self notJoinedHandler:aConversation error:error];
        aConversation = nil;
    }
    
    AVIMConversation *conversation;
    if (isJoined && !error) {
        conversation = aConversation;
    }
    _conversation = conversation;
    [self saveCurrentConversationInfoIfExists];
    [self callbackCurrentConversationEvenNotExists:conversation callback:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self handleLoadHistoryMessagesHandlerIfIsJoined:isJoined];
        }
    }];
}

- (void)callbackCurrentConversationEvenNotExists:(AVIMConversation *)conversation callback:(LCCKBooleanResultBlock)callback {
    if (conversation.createAt) {
        if (!conversation.imClient) {
            [conversation setValue:[LCCKSessionService sharedInstance].client forKey:@"imClient"];
            LCCKLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"imClient is nil");
        }
        BOOL hasDraft = (conversation.lcck_draft.length > 0);
        if (hasDraft) {
            [self loadDraft];
        }
        self.conversationId = conversation.conversationId;
        [self.chatViewModel resetBackgroundImage];
        //系统对话
        if (conversation.members.count == 0) {
            self.navigationItem.title = conversation.lcck_title;
            [self fetchConversationHandler:conversation];
            !callback ?: callback(YES, nil);
            return;
        }
        [[LCChatKit sharedInstance] getProfilesInBackgroundForUserIds:conversation.members callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
            if (!self.disableTitleAutoConfig && (users.count > 0)) {
                [self setupNavigationItemTitleWithConversation:conversation];
            }
            [self fetchConversationHandler:conversation];
            !callback ?: callback(YES, nil);
        }];
    } else {
        [self fetchConversationHandler:conversation];
        NSInteger code = 0;
        NSString *errorReasonText = @"error reason";
        NSDictionary *errorInfo = @{
                                    @"code":@(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                             code:code
                                         userInfo:errorInfo];
        
        !callback ?: callback(NO, error);
    }
}

- (BOOL)isAvailable {
    BOOL isAvailable = self.conversation;
    return isAvailable;
}

//TODO:Conversation为nil,不callback
- (void)handleLoadHistoryMessagesHandlerIfIsJoined:(BOOL)isJoined {
    if (!isJoined) {
        BOOL succeeded = NO;
        //错误码参考：https://leancloud.cn/docs/realtime_v2.html#服务器端错误码说明
        NSInteger code = 4312;
        NSString *errorReasonText = @"拉取对话消息记录被拒绝，当前用户不再对话中";
        NSDictionary *errorInfo = @{
                                    @"code" : @(code),
                                    NSLocalizedDescriptionKey : errorReasonText,
                                    };
        NSError *error = [NSError errorWithDomain:LCCKConversationViewControllerErrorDomain
                                             code:code
                                         userInfo:errorInfo];
        [self loadLatestMessagesHandler:succeeded error:error];
        return;
    }
    __weak __typeof(self) weakSelf = self;
    [self.chatViewModel loadMessagesFirstTimeWithCallback:^(BOOL succeeded, id object, NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            [weakSelf loadLatestMessagesHandler:succeeded error:error];
            BOOL isFirstTimeMeet = (([object count] == 0) && succeeded);
            [self sendWelcomeMessageIfNeeded:isFirstTimeMeet];
        });
    }];
}

- (void)sendWelcomeMessageIfNeeded:(BOOL)isFirstTimeMeet {
    //系统对话
    if (_conversation.members.count == 0) {
        return;
    }
    __block NSString *welcomeMessage;
    LCCKConversationType conversationType = _conversation.lcck_type;
    switch (conversationType) {
        case LCCKConversationTypeSingle:
            welcomeMessage = LCCKLocalizedStrings(@"SingleWelcomeMessage");
            break;
        case LCCKConversationTypeGroup:
            welcomeMessage = LCCKLocalizedStrings(@"GroupWelcomeMessage");
            break;
        default:
            break;
    }
    BOOL isAllowInUserSetting = ([welcomeMessage length] > 0);
    if (!isAllowInUserSetting) {
        return;
    }
    BOOL isSessionAvailable = [LCCKSessionService sharedInstance].connect;
    BOOL isNeverChat = (isSessionAvailable && isFirstTimeMeet);
    BOOL shouldSendWelcome = self.isFirstTimeJoinGroup || isNeverChat;
    if (shouldSendWelcome) {
        [[LCCKUserSystemService sharedInstance] fetchCurrentUserInBackground:^(id<LCCKUserDelegate> user, NSError *error) {
            NSString *userName = user.name;
            if (userName.length > 0 && (conversationType == LCCKConversationTypeGroup)) {
                welcomeMessage = [NSString stringWithFormat:@"%@%@", LCCKLocalizedStrings(@"GroupWelcomeMessageWithNickName"), userName];
            }
            [self sendTextMessage:welcomeMessage];
        }];
    }
}

- (NSString *)userId {
    return [LCChatKit sharedInstance].clientId;
}

#pragma mark - LCCKChatBarDelegate

- (void)chatBar:(LCCKChatBar *)chatBar sendMessage:(NSString *)message {
    [self sendTextMessage:message];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendVoice:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    [self sendVoiceMessageWithPath:voiceFileName time:seconds];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendPictures:(NSArray<UIImage *> *)pictures{
    [self sendImages:pictures];
}

- (void)didInputAtSign:(LCCKChatBar *)chatBar {
    //系统对话
    if (_conversation.members.count == 0) {
        return;
    }
    if (self.conversation.lcck_type == LCCKConversationTypeGroup) {
        [self presentSelectMemberViewController];
    }
}

- (void)presentSelectMemberViewController {
    NSString *cuttentClientId = [LCCKSessionService sharedInstance].clientId;
    NSArray<id<LCCKUserDelegate>> *users = [[LCCKUserSystemService sharedInstance] getCachedProfilesIfExists:self.conversation.members shouldSameCount:YES error:nil];
    LCCKContactListViewController *contactListViewController = [[LCCKContactListViewController alloc] initWithContacts:[NSSet setWithArray:users] userIds:[NSSet setWithArray:self.conversation.members] excludedUserIds:[NSSet setWithArray:@[cuttentClientId]] mode:LCCKContactListModeMultipleSelection];
    [contactListViewController setViewDidDismissBlock:^(LCCKBaseViewController *viewController) {
        [self.chatBar open];
        [self.chatBar beginInputing];
    }];
    [contactListViewController setSelectedContactCallback:^(UIViewController *viewController, NSString *peerId) {
        [viewController dismissViewControllerAnimated:YES completion:^{
            [self.chatBar open];
        }];
        if (peerId.length > 0) {
            NSArray *peerNames = [[LCChatKit sharedInstance] getCachedProfilesIfExists:@[peerId] error:nil];
            NSString *peerName;
            @try {
                id<LCCKUserDelegate> user = peerNames[0];
                peerName = user.name ?: user.clientId;
            } @catch (NSException *exception) {
                peerName = peerId;
            }
            peerName = [NSString stringWithFormat:@"@%@ ", peerName];
            [self.chatBar appendString:peerName];
        }
    }];
    [contactListViewController setSelectedContactsCallback:^(UIViewController *viewController, NSArray<NSString *> *peerIds) {
        if (peerIds.count > 0) {
            NSArray<id<LCCKUserDelegate>> *peers = [[LCCKUserSystemService sharedInstance] getCachedProfilesIfExists:peerIds error:nil];
            NSMutableArray *peerNames = [NSMutableArray arrayWithCapacity:peers.count];
            [peers enumerateObjectsUsingBlock:^(id<LCCKUserDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.name) {
                    [peerNames addObject:obj.name];
                } else {
                    [peerNames addObject:obj.clientId];
                }
            }];
            NSArray *realPeerNames;
            if (peerNames.count > 0) {
                realPeerNames = peerNames;
            } else {
                realPeerNames = peerIds;
            }
            NSString *peerName = [[realPeerNames valueForKey:@"description"] componentsJoinedByString:@" @"];
            peerName = [NSString stringWithFormat:@"@%@ ", peerName];
            [self.chatBar appendString:peerName];
        }
    }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contactListViewController];
    [self presentViewController:navigationController animated:YES completion:^{
        [self.chatBar close];
    }];
}

- (void)chatBar:(LCCKChatBar *)chatBar sendLocation:(CLLocationCoordinate2D)locationCoordinate locationText:(NSString *)locationText {
    [self sendLocationMessageWithLocationCoordinate:locationCoordinate locatioTitle:locationText];
}

- (void)chatBarFrameDidChange:(LCCKChatBar *)chatBar shouldScrollToBottom:(BOOL)shouldScrollToBottom {
    [UIView animateWithDuration:LCCKAnimateDuration animations:^{
        [self.tableView layoutIfNeeded];
        self.allowScrollToBottom = shouldScrollToBottom;
        [self scrollToBottomAnimated:NO];
    } completion:nil];
}


#pragma mark - LCCKChatMessageCellDelegate

- (void)messageCellTappedHead:(LCCKChatMessageCell *)messageCell {
    LCCKOpenProfileBlock openProfileBlock = [LCCKUIService sharedInstance].openProfileBlock;
    !openProfileBlock ?: openProfileBlock(messageCell.message.senderId, messageCell.message.sender, self);
}

- (void)messageCellTappedBlank:(LCCKChatMessageCell *)messageCell {
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

- (void)messageCellTappedMessage:(LCCKChatMessageCell *)messageCell {
    if (!messageCell) {
        return;
    }
    [self.chatBar close];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:messageCell];
    LCCKMessage *message = [self.chatViewModel.dataArray lcck_messageAtIndex:indexPath.row];
    switch (messageCell.mediaType) {
        case kAVIMMessageMediaTypeAudio: {
            NSString *voiceFileName = message.voicePath;//必须带后缀，.mp3；
            [[LCCKAVAudioPlayer sharePlayer] playAudioWithURLString:voiceFileName identifier:message.messageId];
        }
            break;
        case kAVIMMessageMediaTypeImage: {
            ///FIXME:4S等低端机型在图片超过1M时，有几率会Crash，尤其是全景图。
            LCCKPreviewImageMessageBlock previewImageMessageBlock = [LCCKUIService sharedInstance].previewImageMessageBlock;
            UIImageView *placeholderView = [(LCCKChatImageMessageCell *)messageCell messageImageView];
            NSDictionary *userInfo = @{
                                       /// 传递触发的UIViewController对象
                                       LCCKPreviewImageMessageUserInfoKeyFromController : self,
                                       /// 传递触发的UIView对象
                                       LCCKPreviewImageMessageUserInfoKeyFromView : self.tableView,
                                       LCCKPreviewImageMessageUserInfoKeyFromPlaceholderView : placeholderView
                                       };
            NSArray *allVisibleImages = nil;
            NSArray *allVisibleThumbs = nil;
            NSNumber *selectedMessageIndex = nil;
            [self.chatViewModel getAllVisibleImagesForSelectedMessage:messageCell.message allVisibleImages:&allVisibleImages allVisibleThumbs:&allVisibleThumbs selectedMessageIndex:&selectedMessageIndex];
            
            if (previewImageMessageBlock) {
                previewImageMessageBlock(selectedMessageIndex.unsignedIntegerValue, allVisibleImages, allVisibleThumbs, userInfo);
            } else {
                [self previewImageMessageWithInitialIndex:selectedMessageIndex.unsignedIntegerValue allVisibleImages:allVisibleImages allVisibleThumbs:allVisibleThumbs placeholderImageView:placeholderView fromViewController:self];
            }
        }
            break;
        case kAVIMMessageMediaTypeLocation: {
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
        default: {
//            //TODO:自定义消息的点击事件
//            NSString *formatString = @"\n\n\
//            ------ BEGIN NSException Log ---------------\n \
//            class name: %@                              \n \
//            ------line: %@                              \n \
//            ----reason: %@                              \n \
//            ------ END -------------------------------- \n\n";
//            NSString *reason = [NSString stringWithFormat:formatString,
//                                @(__PRETTY_FUNCTION__),
//                                @(__LINE__),
//                                @"messageCell.messageType not handled"];
//            //手动创建一个异常导致的崩溃事件 http://is.gd/EfVfN0
//            @throw [NSException exceptionWithName:NSGenericException
//                                           reason:reason
//                                         userInfo:nil];
        }
            break;
    }
    [self.chatBar open];
}

- (void)previewImageMessageWithInitialIndex:(NSUInteger)initialIndex
                           allVisibleImages:(NSArray *)allVisibleImages
                           allVisibleThumbs:(NSArray *)allVisibleThumbs
                       placeholderImageView:(UIImageView *)placeholderImageView
                         fromViewController:(LCCKConversationViewController *)fromViewController{
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] initWithCapacity:[allVisibleImages count]];
    NSMutableArray *thumbs = [[NSMutableArray alloc] initWithCapacity:[allVisibleThumbs count]];
    LCCKPhoto *photo;
    for (NSUInteger index = 0; index < allVisibleImages.count; index++) {
        id image_ = allVisibleImages[index];
        
        if ([image_ isKindOfClass:[UIImage class]]) {
            photo = [LCCKPhoto photoWithImage:image_];
        } else {
            photo = [LCCKPhoto photoWithURL:image_];
        }
        if (index == initialIndex) {
            photo.placeholderImageView = placeholderImageView;
        }
        [photos addObject:photo];
    }
    // Options
    self.photos = photos;
    self.thumbs = thumbs;
    // Create browser
    LCCKPhotoBrowser *browser = [[LCCKPhotoBrowser alloc] initWithPhotos:photos];
    browser.delegate = self;
    [browser setInitialPageIndex:initialIndex];
    browser.usePopAnimation = YES;
    browser.animationDuration = 0.15;
    // Show
    [fromViewController presentViewController:browser animated:YES completion:nil];
}

- (void)avatarImageViewLongPressed:(LCCKChatMessageCell *)messageCell {
    if (messageCell.message.senderId == [LCChatKit sharedInstance].clientId || self.conversation.lcck_type == LCCKConversationTypeSingle) {
        return;
    }
    NSString *userName = messageCell.message.localDisplayName;
    if (userName.length == 0 || !userName || [userName isEqualToString:LCCKLocalizedStrings(@"nickNameIsNil")]) {
        return;
    }
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

- (void)fileMessageDidDownload:(LCCKChatMessageCell *)messageCell {
    [self reloadAfterReceiveMessage];
}

- (void)messageCell:(LCCKChatMessageCell *)messageCell didTapLinkText:(NSString *)linkText linkType:(MLLinkType)linkType {
    switch (linkType) {
        case MLLinkTypeURL: {
            linkText =  [linkText lowercaseString];
            LCCKWebViewController *webViewController = [[LCCKWebViewController alloc] init];
            if (![linkText hasPrefix:@"http"]) {
                linkText = [NSString stringWithFormat:@"http://%@", linkText];
            }
            webViewController.URL = [NSURL URLWithString:linkText];
            LCCKSafariActivity *activity = [[LCCKSafariActivity alloc] init];
            webViewController.applicationActivities = @[activity];
            webViewController.excludedActivityTypes = @[UIActivityTypeMail, UIActivityTypeMessage, UIActivityTypePostToWeibo];
            [self.navigationController pushViewController:webViewController animated:YES];
        }
            break;
        case MLLinkTypePhoneNumber: {
            NSString *title = [NSString stringWithFormat:@"%@?", LCCKLocalizedStrings(@"call")];
            LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                               message:@""
                                                                        preferredStyle:LCCKAlertControllerStyleAlert];
            NSString *cancelActionTitle = LCCKLocalizedStrings(@"cancel");
            LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {}];
            [alert addAction:cancelAction];
            NSString *resendActionTitle = LCCKLocalizedStrings(@"call");
            LCCKAlertAction* resendAction = [LCCKAlertAction actionWithTitle:resendActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {
                                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat: @"tel:%@", linkText]]];
                                                                     }];
            [alert addAction:resendAction];
            [alert showWithSender:nil controller:self animated:YES completion:NULL];
        }
            break;
        default:
            break;
    }
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
    if (messageCell.mediaType == kAVIMMessageMediaTypeImage) {
        [(LCCKChatImageMessageCell *)messageCell setUploadProgress:progress];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        messageCell.messageSendState = sendState;
    });
}

- (void)reloadAfterReceiveMessage {
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

#pragma mark - LCCKAVAudioPlayerDelegate

- (void)loadMoreMessagesScrollTotop {
    [self.chatViewModel loadOldMessages];
}

- (void)updateStatusView {
    if (!self.shouldCheckSessionStatus) {
        return;
    }
    BOOL isConnected = [LCCKSessionService sharedInstance].connect;
    if (isConnected) {
        self.clientStatusView.hidden = YES;
    } else {
        self.clientStatusView.hidden = NO;
    }
}

@end
