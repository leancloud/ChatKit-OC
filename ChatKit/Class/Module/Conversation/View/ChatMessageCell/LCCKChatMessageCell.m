//
//  LCCKChatMessageCell.m
//  LCCKChatExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/13.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatMessageCell.h"

#import "LCCKChatTextMessageCell.h"
#import "LCCKChatImageMessageCell.h"
#import "LCCKChatVoiceMessageCell.h"
#import "LCCKChatSystemMessageCell.h"
#import "LCCKChatLocationMessageCell.h"

#import <objc/runtime.h>
#import "LCCKBubbleImageFactory.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#else
#import "UIImageView+WebCache.h"
#endif

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

#import "UIImageView+LCCKExtension.h"
#import "UIImage+LCCKExtension.h"
#import "NSObject+LCCKExtension.h"
#import "LCCKConstants.h"

NSMutableDictionary const *LCCKChatMessageCellMediaTypeDict = nil;

static CGFloat const kAvatarImageViewWidth = 50.f;
static CGFloat const kAvatarImageViewHeight = kAvatarImageViewWidth;
static CGFloat const LCCKMessageSendStateViewWidthHeight = 30.f;
static CGFloat const LCCKMessageSendStateViewLeftOrRightToMessageContentView = 2.f;
static CGFloat const LCCKAvatarToMessageContent = 5.f;

static CGFloat const LCCKAvatarBottomToMessageContentTop = -1.f;


static CGFloat const LCCK_MSG_CELL_EDGES_OFFSET = 16;
static CGFloat const LCCK_MSG_CELL_NICKNAME_HEIGHT = 16;
static CGFloat const LCCK_MSG_CELL_NICKNAME_FONT_SIZE = 12;

@interface LCCKChatMessageCell ()<LCCKSendImageViewDelegate>

@property (nonatomic, strong, readwrite) LCCKMessage *message;
@property (nonatomic, assign, readwrite) AVIMMessageMediaType mediaType;
@property (nonatomic, strong) UIColor *conversationViewSenderNameTextColor;

@end

@implementation LCCKChatMessageCell

+ (void)registerCustomMessageCell {
    [self registerSubclass];
}

+ (void)registerSubclass {
    if ([self conformsToProtocol:@protocol(LCCKChatMessageCellSubclassing)]) {
        Class<LCCKChatMessageCellSubclassing> class = self;
        AVIMMessageMediaType mediaType = [class classMediaType];
        [self registerClass:class forMediaType:mediaType];
    }
}

+ (Class)classForMediaType:(AVIMMessageMediaType)mediaType {
    NSNumber *key = [NSNumber numberWithInteger:mediaType];
    Class class = [LCCKChatMessageCellMediaTypeDict objectForKey:key];
    if (!class) {
        class = self;
    }
    return class;
}

+ (void)registerClass:(Class)class forMediaType:(AVIMMessageMediaType)mediaType {
    if (!LCCKChatMessageCellMediaTypeDict) {
        LCCKChatMessageCellMediaTypeDict = [[NSMutableDictionary alloc] init];
    }
    NSNumber *key = [NSNumber numberWithInteger:mediaType];
    Class c = [LCCKChatMessageCellMediaTypeDict objectForKey:key];
    if (!c || [class isSubclassOfClass:c]) {
        [LCCKChatMessageCellMediaTypeDict setObject:class forKey:key];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setup];
    }
    return self;
}

// add support for LCCKMenuItem. Needs to be called once per class.
+ (void)load {
    [LCCKMenuItem installMenuHandlerForObject:self];
}

+ (void)initialize {
    [LCCKMenuItem installMenuHandlerForObject:self];
}

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

#pragma mark - Override Methods

- (BOOL)showName {
    BOOL isMessageOwner = self.messageOwner == LCCKMessageOwnerTypeOther;
    BOOL isMessageChatTypeGroup = self.messageChatType == LCCKConversationTypeGroup;
    if (isMessageOwner && isMessageChatTypeGroup) {
        self.nickNameLabel.hidden = NO;
        return YES;
    }
    self.nickNameLabel.hidden = YES;
    return NO;
}

- (void)updateConstraints {
    [super updateConstraints];
    if (self.messageOwner == LCCKMessageOwnerTypeSystem || self.messageOwner == LCCKMessageOwnerTypeUnknown) {
        return;
    }
    if (self.messageOwner == LCCKMessageOwnerTypeSelf) {
        if (self.avatarImageView.superview) {
            [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.contentView.mas_right).with.offset(-LCCK_MSG_CELL_EDGES_OFFSET);
                make.top.equalTo(self.contentView.mas_top).with.offset(LCCK_MSG_CELL_EDGES_OFFSET);
                make.width.equalTo(@(kAvatarImageViewWidth));
                make.height.equalTo(@(kAvatarImageViewHeight));
            }];
        }
        if (self.nickNameLabel.superview) {
            [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.avatarImageView.mas_top);
                make.right.equalTo(self.avatarImageView.mas_left).with.offset(-LCCK_MSG_CELL_EDGES_OFFSET);
                make.width.mas_lessThanOrEqualTo(@120);
                make.height.equalTo(@0);
            }];
        }
        if (self.messageContentView.superview) {
            [self.messageContentView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.avatarImageView.mas_left).with.offset(-LCCKAvatarToMessageContent);
                make.top.equalTo(self.nickNameLabel.mas_bottom).with.offset(self.showName ? 0 : LCCKAvatarBottomToMessageContentTop);
                CGFloat width = [UIApplication sharedApplication].keyWindow.frame.size.width;
                CGFloat height = [UIApplication sharedApplication].keyWindow.frame.size.height;
                CGFloat widthLimit = MIN(width, height)/5 * 3;
                
                make.width.lessThanOrEqualTo(@(widthLimit)).priorityHigh();
                make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-LCCK_MSG_CELL_EDGES_OFFSET).priorityLow();
            }];
        }
        if (self.messageSendStateView.superview) {
            [self.messageSendStateView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.messageContentView.mas_left).with.offset(-LCCKMessageSendStateViewLeftOrRightToMessageContentView);
                make.centerY.equalTo(self.messageContentView.mas_centerY);
                make.width.equalTo(@(LCCKMessageSendStateViewWidthHeight));
                make.height.equalTo(@(LCCKMessageSendStateViewWidthHeight));
            }];
        }
        if (self.messageReadStateImageView.superview) {
            [self.messageReadStateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(self.messageContentView.mas_left).with.offset(-8);
                make.centerY.equalTo(self.messageContentView.mas_centerY);
                make.width.equalTo(@10);
                make.height.equalTo(@10);
            }];
        }
    } else if (self.messageOwner == LCCKMessageOwnerTypeOther){
        if (self.avatarImageView.superview) {
            [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.contentView.mas_left).with.offset(LCCK_MSG_CELL_EDGES_OFFSET);
                make.top.equalTo(self.contentView.mas_top).with.offset(LCCK_MSG_CELL_EDGES_OFFSET);
                make.width.equalTo(@(kAvatarImageViewWidth));
                make.height.equalTo(@(kAvatarImageViewHeight));
            }];
        }
        if (self.nickNameLabel.superview) {
            [self.nickNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.avatarImageView.mas_top);
                make.left.equalTo(self.avatarImageView.mas_right).with.offset(LCCK_MSG_CELL_EDGES_OFFSET);
                make.width.mas_lessThanOrEqualTo(@120);
                make.height.equalTo(self.messageChatType == LCCKConversationTypeGroup ? @(LCCK_MSG_CELL_NICKNAME_HEIGHT) : @0);
            }];
        }
        if (self.messageContentView.superview) {
            [self.messageContentView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.avatarImageView.mas_right).with.offset(LCCKAvatarToMessageContent);
                make.top.equalTo(self.nickNameLabel.mas_bottom).with.offset(self.showName ? 0 : LCCKAvatarBottomToMessageContentTop);
                CGFloat width = [UIApplication sharedApplication].keyWindow.frame.size.width;
                CGFloat height = [UIApplication sharedApplication].keyWindow.frame.size.height;
                CGFloat widthLimit = MIN(width, height)/5 * 3;
                make.width.lessThanOrEqualTo(@(widthLimit)).priorityHigh();
                make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-LCCK_MSG_CELL_EDGES_OFFSET).priorityLow();
            }];
        }
        if (self.messageSendStateView.superview) {
            [self.messageSendStateView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.messageContentView.mas_right).with.offset(LCCKMessageSendStateViewLeftOrRightToMessageContentView);
                make.centerY.equalTo(self.messageContentView.mas_centerY);
                make.width.equalTo(@(LCCKMessageSendStateViewWidthHeight));
                make.height.equalTo(@(LCCKMessageSendStateViewWidthHeight));
            }];
        }
        if (self.messageReadStateImageView.superview) {
            [self.messageReadStateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.messageContentView.mas_right).with.offset(8);
                make.centerY.equalTo(self.messageContentView.mas_centerY);
                make.width.equalTo(@10);
                make.height.equalTo(@10);
            }];
        }
    }
    
    if (self.messageContentBackgroundImageView.superview) {
        [self.messageContentBackgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.messageContentView);
        }];
    }
    
    if (!self.showName) {
        if (self.nickNameLabel.superview) {
            [self.nickNameLabel mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.equalTo(@0);
            }];
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint touchPoint = [[touches anyObject] locationInView:self.contentView];
    if (CGRectContainsPoint(self.messageContentView.frame, touchPoint)) {
        self.messageContentBackgroundImageView.highlighted = YES;
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.messageContentBackgroundImageView.highlighted = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.messageContentBackgroundImageView.highlighted = NO;
}

#pragma mark - Private Methods

- (BOOL)isAbleToTap {
    BOOL isAbleToTap = NO;
    //For Link handle
    if (self.mediaType < 0 && ![self isKindOfClass:[LCCKChatTextMessageCell class]]) {
        isAbleToTap = YES;
    }
    return isAbleToTap;
}

- (void)addGeneralView {
    [self.contentView addSubview:self.avatarImageView];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.messageContentView];
    [self.contentView addSubview:self.messageReadStateImageView];
    [self.contentView addSubview:self.messageSendStateView];
    
    [self.messageContentBackgroundImageView setImage:[LCCKBubbleImageFactory bubbleImageViewForType:self.messageOwner messageType:self.mediaType isHighlighted:NO]];
    [self.messageContentBackgroundImageView setHighlightedImage:[LCCKBubbleImageFactory bubbleImageViewForType:self.messageOwner messageType:self.mediaType isHighlighted:YES]];
    
    self.messageContentView.layer.mask.contents = (__bridge id _Nullable)(self.messageContentBackgroundImageView.image.CGImage);
    [self.contentView insertSubview:self.messageContentBackgroundImageView belowSubview:self.messageContentView];
    [self updateConstraintsIfNeeded];
    
    self.messageSendStateView.hidden = YES;
    self.messageReadStateImageView.hidden = YES;
    

    if (self.isAbleToTap) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.contentView addGestureRecognizer:tap];
    }
    UITapGestureRecognizer *avatarImageViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageViewHandleTap:)];
    self.avatarImageView.userInteractionEnabled = YES;
    [self.avatarImageView addGestureRecognizer:avatarImageViewTap];
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [recognizer setMinimumPressDuration:0.4f];
    [self addGestureRecognizer:recognizer];
}

- (void)setup {
    if (![self conformsToProtocol:@protocol(LCCKChatMessageCellSubclassing)]) {
        [NSException raise:@"LCCKChatMessageCellNotSubclassException" format:@"Class does not conform LCCKChatMessageCellSubclassing protocol."];
    }
    self.mediaType = [[self class] classMediaType];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];;
}

#pragma mark - Public Methods

- (void)configureCellWithData:(id)message {
    NSString *nickName = nil;
    NSURL *avatarURL = nil;
    LCCKMessageSendState sendStatus;
    if ([message lcck_isCustomMessage]) {
        NSString *senderClientId = [(AVIMTypedMessage *)message clientId];
        NSError *error;
        //TODO:如果我正在群里聊天，这时有人进入群聊，需要异步获取头像等信息，模仿ConversationList的做法。
        [[LCCKUserSystemService sharedInstance] getCachedProfileIfExists:senderClientId name:&nickName avatarURL:&avatarURL error:&error];
        if (!nickName)  { nickName = senderClientId; }
        self.message = nil;
        sendStatus = (LCCKMessageSendState)[(AVIMTypedMessage *)message status];
    } else {
        self.message = message;
        nickName = self.message.localDisplayName;
        avatarURL = self.message.sender.avatarURL;
        sendStatus = self.message.sendStatus;
        //FIXME: SDK 暂不支持已读未读
        //        if ([(LCCKMessage *)message messageReadState]) {
        //            self.messageReadState = self.message.messageReadState;
        //        }
    }
    self.nickNameLabel.text = nickName;
    [self.avatarImageView sd_setImageWithURL:avatarURL
                            placeholderImage:({
        NSString *imageName = @"Placeholder_Avatar";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[self class]];
        image;})
     ];
    self.messageSendState = sendStatus;
}

#pragma mark - Private Methods

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        CGPoint tapPoint = [tap locationInView:self.contentView];
        if (CGRectContainsPoint(self.messageContentView.frame, tapPoint)) {
            [self.delegate messageCellTappedMessage:self];
        }  else if (!CGRectContainsPoint(self.avatarImageView.frame, tapPoint)) {
            //FIXME:Never invoked
            [self.delegate messageCellTappedBlank:self];
        }
    }
}

- (void)avatarImageViewHandleTap:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        [self.delegate messageCellTappedHead:self];
    }
}

#pragma mark - Setters

- (void)setMessageSendState:(LCCKMessageSendState)messageSendState {
    _messageSendState = messageSendState;
    if (self.messageOwner == LCCKMessageOwnerTypeOther) {
        self.messageSendStateView.hidden = YES;
    }
    self.messageSendStateView.messageSendState = messageSendState;
}

- (void)setMessageReadState:(LCCKMessageReadState)messageReadState {
    _messageReadState = messageReadState;
    if (self.messageOwner == LCCKMessageOwnerTypeSelf) {
        self.messageSendStateView.hidden = YES;
    }
    switch (_messageReadState) {
            case LCCKMessageUnRead:
            self.messageReadStateImageView.hidden = NO;
            break;
        default:
            self.messageReadStateImageView.hidden = YES;
            break;
    }
}

#pragma mark - Getters

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock = [LCChatKit sharedInstance].avatarImageViewCornerRadiusBlock;
        if (avatarImageViewCornerRadiusBlock) {
            CGSize avatarImageViewSize = CGSizeMake(kAvatarImageViewWidth, kAvatarImageViewHeight);
            CGFloat avatarImageViewCornerRadius = avatarImageViewCornerRadiusBlock(avatarImageViewSize);
            self.avatarImageView.lcck_cornerRadius = avatarImageViewCornerRadius;
        }
        [self bringSubviewToFront:_avatarImageView];
    }
    return _avatarImageView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:LCCK_MSG_CELL_NICKNAME_FONT_SIZE];
        _nickNameLabel.textColor = self.conversationViewSenderNameTextColor;
        _nickNameLabel.text = @"nickname";
        [_nickNameLabel sizeToFit];
    }
    return _nickNameLabel;
}

- (LCCKContentView *)messageContentView {
    if (!_messageContentView) {
        _messageContentView = [[LCCKContentView alloc] init];
    }
    return _messageContentView;
}

- (UIImageView *)messageReadStateImageView {
    if (!_messageReadStateImageView) {
        _messageReadStateImageView = [[UIImageView alloc] init];
    }
    return _messageReadStateImageView;
}

- (LCCKMessageSendStateView *)messageSendStateView {
    if (!_messageSendStateView) {
        _messageSendStateView = [[LCCKMessageSendStateView alloc] init];
        _messageSendStateView.delegate = self;
    }
    return _messageSendStateView;
}

- (UIImageView *)messageContentBackgroundImageView {
    if (!_messageContentBackgroundImageView) {
        _messageContentBackgroundImageView = [[UIImageView alloc] init];
    }
    return _messageContentBackgroundImageView;
}

- (LCCKConversationType)messageChatType {
    if ([self.reuseIdentifier lcck_containsString:LCCKCellIdentifierGroup]) {
        return LCCKConversationTypeGroup;
    }
    return LCCKConversationTypeSingle;
}

- (LCCKMessageOwnerType)messageOwner {
    if ([self.reuseIdentifier lcck_containsString:LCCKCellIdentifierOwnerSelf]) {
        return LCCKMessageOwnerTypeSelf;
    } else if ([self.reuseIdentifier lcck_containsString:LCCKCellIdentifierOwnerOther]) {
        return LCCKMessageOwnerTypeOther;
    } else if ([self.reuseIdentifier lcck_containsString:LCCKCellIdentifierOwnerSystem]) {
        return LCCKMessageOwnerTypeSystem;
    }
    return LCCKMessageOwnerTypeUnknown;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPressGes
{
    if (longPressGes.state == UIGestureRecognizerStateBegan) {
        CGPoint longPressPoint = [longPressGes locationInView:self.contentView];
        if (!CGRectContainsPoint(self.messageContentView.frame, longPressPoint)) {
            if (CGRectContainsPoint(self.avatarImageView.frame, longPressPoint)) {
                if ([self.delegate respondsToSelector:@selector(avatarImageViewLongPressed:)]) {
                    [self.delegate avatarImageViewLongPressed:self];
                }
            }
            return;
        }
        [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
        NSUInteger delaySeconds = LCCKAnimateDuration;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            [self becomeFirstResponder];
            LCCKLongPressMessageBlock longPressMessageBlock = [LCChatKit sharedInstance].longPressMessageBlock;
            NSDictionary *userInfo = @{ LCCKLongPressMessageUserInfoKeyFromController: self.delegate,
                                        LCCKLongPressMessageUserInfoKeyFromView: self.tableView,
                                        LCCKLongPressMessageUserInfoKeyMessageOwner: @(self.messageOwner),
                                        LCCKLongPressMessageUserInfoKeyMessageCell: self };
            NSArray *menuItems = [NSArray array];
            if (longPressMessageBlock) {
                menuItems = longPressMessageBlock(self.message, userInfo);
            } else {
                LCCKMenuItem *copyItem = [[LCCKMenuItem alloc] initWithTitle:LCCKLocalizedStrings(@"copy") block:^{
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    [pasteboard setString:[self.message text]];
                }];
                if (self.mediaType == kAVIMMessageMediaTypeText) {
                    menuItems = @[copyItem];
                }
            }
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            [menuController setMenuItems:menuItems];
            [menuController setArrowDirection:UIMenuControllerArrowDown];
            UITableView *tableView = self.tableView;
            CGRect targetRect = [self convertRect:self.messageContentView.frame toView:tableView];
            [menuController setTargetRect:targetRect inView:tableView];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMenuWillShowNotification:) name:UIMenuControllerWillShowMenuNotification object:nil];
            [menuController setMenuVisible:YES animated:YES];
        });
    }
}

#pragma mark - Notifications

- (void)handleMenuWillHideNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerWillHideMenuNotification
                                                  object:nil];
}

- (void)handleMenuWillShowNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerWillShowMenuNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMenuWillHideNotification:)
                                                 name:UIMenuControllerWillHideMenuNotification
                                               object:nil];
}

#pragma mark -
#pragma mark - LCCKSendImageViewDelegate Method

- (void)resendMessage:(id)sender {
    if ([self.delegate respondsToSelector:@selector(resendMessage:)]) {
        [self.delegate resendMessage:self];
    }
}

- (UIColor *)conversationViewSenderNameTextColor {
    if (_conversationViewSenderNameTextColor) {
        return _conversationViewSenderNameTextColor;
    }
    _conversationViewSenderNameTextColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"ConversationView-SenderName-TextColor"];
    return _conversationViewSenderNameTextColor;
}

- (UIColor *)conversationViewMessageRightTextColor {
    if (_conversationViewMessageRightTextColor) {
        return _conversationViewMessageRightTextColor;
    }
    _conversationViewMessageRightTextColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"ConversationView-Message-Right-TextColor"];
    return _conversationViewMessageRightTextColor;
}

- (UIColor *)conversationViewMessageLeftTextColor {
    if (_conversationViewMessageLeftTextColor) {
        return _conversationViewMessageLeftTextColor;
    }
    _conversationViewMessageLeftTextColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"ConversationView-Message-Left-TextColor"];
    return _conversationViewMessageLeftTextColor;
}

@end

