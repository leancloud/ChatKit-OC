//
//  XHMessageTableViewCell.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-4-24.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//
//LCIMDebugging定义为1表示【debugging】 ，注释、不定义或者0 表示【debugging】
/* Set LCIMDebugging =1 in preprocessor macros under build settings to enable 【debugging】.*/
#define LCIMDebugging 1

#import "XHMessageTableViewCell.h"
#import "XHMessageStatusView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "LCIMConstants.h"
NSString *const senderCellIdentifier = @"XHMessageTableViewCellSender";
NSString *const receiverCellIdentifier = @"XHMessageTableViewCellReceiver";

static const CGFloat kXHLabelPadding = 5.0f;
static const CGFloat kXHTimeStampLabelHeight = 20.0f;
static const CGFloat kXHPeerNameLabelHeight = 20.0f;
static const CGFloat kXHAvatorPaddingX = 8.0;
static const CGFloat kXHAvatorPaddingY = 15;
//气泡底部距离ContentView底部的距离
static const CGFloat kXHBubbleMessageViewTopPadding = 0;
static const CGFloat kXHBubbleMessageViewBottomPadding = 8;

/*!
 * Cell 顶端到 Avator 顶部的距离，根据时间戳的显示与否有所不同。显示时间戳时，时间戳上下总共有 2*kXHLabelPadding个高度，而不显示时间戳时是一个kXHAvatorPaddingY高度
 */
#define kTimeStampZoneHeight(displayTimestamp)  (kXHAvatorPaddingY + (displayTimestamp ? kXHTimeStampLabelHeight : 0))
#define kPeerNameZoneHeight(displayPeerName)  (displayPeerName ? kXHPeerNameLabelHeight : 0)


@interface XHMessageTableViewCell ()

@property (nonatomic, weak, readwrite) XHMessageBubbleView *messageBubbleView;

@property (nonatomic, weak, readwrite) UIButton *avatorButton;

@property (nonatomic, weak, readwrite) UILabel *peerNameLabel;

@property (nonatomic, weak, readwrite) XHMessageStatusView *statusView;

@property (nonatomic, weak, readwrite) LKBadgeView *timestampLabel;

/**
 *  是否显示时间轴Label
 */
@property (nonatomic, assign) BOOL displayTimestamp;

/*!
 * 是否显示聊天对象的昵称，单聊是是指对方，群聊时是指其他群成员，默认 NO。
 */
@property (nonatomic, assign) BOOL displayPeerName;


/**
 *  1、是否显示Time Line的label
 *
 *  @param message 需要配置的目标消息Model
 */
- (void)configureTimestamp:(BOOL)displayTimestamp atMessage:(id<XHMessageModel>)message;

/**
 *  2、配置头像
 *
 *  @param message 需要配置的目标消息Model
 */
- (void)configAvatorWithMessage:(id<XHMessageModel>)message;

/**
 *  3、配置需要显示什么消息内容，比如语音、文字、视频、图片
 *
 *  @param message 需要配置的目标消息Model
 */
- (void)configureMessageBubbleViewWithMessage:(id<XHMessageModel>)message;

/**
 *  头像按钮，点击事件
 *
 *  @param sender 头像按钮对象
 */
- (void)avatorButtonClicked:(UIButton *)sender;

/**
 *  统一一个方法隐藏MenuController，多处需要调用
 */
- (void)setupNormalMenuController;

/**
 *  点击Cell的手势处理方法，用于隐藏MenuController的
 *
 *  @param tapGestureRecognizer 点击手势对象
 */
- (void)tapGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer;

/**
 *  长按Cell的手势处理方法，用于显示MenuController的
 *
 *  @param longPressGestureRecognizer 长按手势对象
 */
- (void)longPressGestureRecognizerHandle:(UILongPressGestureRecognizer *)longPressGestureRecognizer;

/**
 *  单击手势处理方法，用于点击多媒体消息触发方法，比如点击语音需要播放的回调、点击图片需要查看大图的回调
 *
 *  @param tapGestureRecognizer 点击手势对象
 */
- (void)sigleTapGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer;

/**
 *  双击手势处理方法，用于双击文本消息，进行放大文本的回调
 *
 *  @param tapGestureRecognizer 双击手势对象
 */
- (void)doubleTapGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer;

@end

@implementation XHMessageTableViewCell

- (void)avatorButtonClicked:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didSelectedAvatorOnMessage:atIndexPath:)]) {
        [self.delegate didSelectedAvatorOnMessage:self.messageBubbleView.message atIndexPath:self.indexPath];
    }
}

-(void)retryButtonClicked:(UIButton*)sender{
    if([_delegate respondsToSelector:@selector(didRetrySendMessage:atIndexPath:)]){
        [_delegate didRetrySendMessage:self.messageBubbleView.message atIndexPath:self.indexPath];
    }
}

#pragma mark - Copying Method

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)becomeFirstResponder {
    return [super becomeFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copied:) || action == @selector(transpond:) || action == @selector(favorites:) || action == @selector(more:));
}

#pragma mark - Menu Actions

- (void)copied:(id)sender {
    switch (self.messageBubbleView.message.messageMediaType) {
        case XHBubbleMessageMediaTypeText:
            [[UIPasteboard generalPasteboard] setString:self.messageBubbleView.displayTextView.text];
            break;
        case XHBubbleMessageMediaTypePhoto:
            [[UIPasteboard generalPasteboard] setImage:self.messageBubbleView.bubblePhotoImageView.messagePhoto];
            break;
        case XHBubbleMessageMediaTypeLocalPosition:
            [[UIPasteboard generalPasteboard] setString:self.messageBubbleView.geolocationsLabel.text];
            break;
        case XHBubbleMessageMediaTypeEmotion:
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypeVoice:
            break;
    }
    [self resignFirstResponder];
    DLog(@"Cell was copy");
}

- (void)transpond:(id)sender {
    DLog(@"Cell was transpond");
}

- (void)favorites:(id)sender {
    DLog(@"Cell was favorites");
}

- (void)more:(id)sender {
    DLog(@"Cell was more");
}

#pragma mark - Setters

- (void)configureCellWithMessage:(id<XHMessageModel>)message
               displaysTimestamp:(BOOL)displayTimestamp
                displaysPeerName:(BOOL)dispalyPeerName {
    // 1、是否显示Time Line的label
    [self configureTimestamp:displayTimestamp atMessage:message];
    
    // 2、配置头像
    [self configureAvatorWithMessage:message];
    
    // 3、配置用户名
    [self configurePeerName:dispalyPeerName atMessage:message];
    
    // 4、配置需要显示什么消息内容，比如语音、文字、视频、图片
    [self configureMessageBubbleViewWithMessage:message];
    
    [self configureStatusViewWithMessage:message];
    [self layoutIfNeeded];
}

- (void)configureTimestamp:(BOOL)displayTimestamp atMessage:(id<XHMessageModel>)message {
    self.displayTimestamp = displayTimestamp;
    self.timestampLabel.hidden = !displayTimestamp;
    if (displayTimestamp) {
        self.timestampLabel.text = [NSDateFormatter localizedStringFromDate:message.timestamp
                                                                  dateStyle:NSDateFormatterMediumStyle
                                                                  timeStyle:NSDateFormatterShortStyle];
    }
}

- (void)configurePeerName:(BOOL)displayPeerName atMessage:(id<XHMessageModel>)message {
    self.displayPeerName = displayPeerName;
    self.peerNameLabel.hidden = !displayPeerName;
    if (displayPeerName) {
        self.peerNameLabel.text = [message sender];
    }
}

- (void)configureAvatorWithMessage:(id<XHMessageModel>)message {
    NSString *imageName = @"Placeholder_Avator";
    NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
    UIImage *avatorImage = [UIImage imageNamed:imageNameWithBundlePath];
    
    if (message.avator) {
        [self.avatorButton setImage:message.avator forState:UIControlStateNormal];
    } else if(message.avatorUrl){
        [self.avatorButton.imageView sd_setImageWithURL:[NSURL URLWithString:message.avatorUrl] placeholderImage:avatorImage];
    } else {
        [self.avatorButton setImage:[XHMessageAvatorFactory avatorImageNamed:avatorImage messageAvatorType:XHMessageAvatorTypeSquare] forState:UIControlStateNormal];
    }
}

- (void)configureMessageBubbleViewWithMessage:(id<XHMessageModel>)message {
    XHBubbleMessageMediaType currentMediaType = message.messageMediaType;
    for (UIGestureRecognizer *gesTureRecognizer in self.messageBubbleView.bubbleImageView.gestureRecognizers) {
        [self.messageBubbleView.bubbleImageView removeGestureRecognizer:gesTureRecognizer];
    }
    for (UIGestureRecognizer *gesTureRecognizer in self.messageBubbleView.bubblePhotoImageView.gestureRecognizers) {
        [self.messageBubbleView.bubblePhotoImageView removeGestureRecognizer:gesTureRecognizer];
    }
    switch (currentMediaType) {
        case XHBubbleMessageMediaTypePhoto:
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypeLocalPosition: {
            UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sigleTapGestureRecognizerHandle:)];
            [self.messageBubbleView.bubblePhotoImageView addGestureRecognizer:tapGestureRecognizer];
            break;
        }
        case XHBubbleMessageMediaTypeText:
        case XHBubbleMessageMediaTypeVoice:
        case XHBubbleMessageMediaTypeEmotion: {
            UITapGestureRecognizer *tapGestureRecognizer;
            if (currentMediaType == XHBubbleMessageMediaTypeText) {
                tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureRecognizerHandle:)];
            } else {
                tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sigleTapGestureRecognizerHandle:)];
            }
            tapGestureRecognizer.numberOfTapsRequired = (currentMediaType == XHBubbleMessageMediaTypeText ? 2 : 1);
            [self.messageBubbleView.bubbleImageView addGestureRecognizer:tapGestureRecognizer];
            break;
        }
    }
    [self.messageBubbleView configureCellWithMessage:message];
}

- (void)configureStatusViewWithMessage:(id<XHMessageModel>)message {
    //NSString* str=[NSString stringWithFormat:@"%d",[message status]];
    [_statusView setStatus:[message status]];
}

#pragma mark - Gestures

- (void)setupNormalMenuController {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (menu.isMenuVisible) {
        [menu setMenuVisible:NO animated:YES];
    }
}

- (void)tapGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self updateMenuControllerVisiable];
}

- (void)updateMenuControllerVisiable {
    [self setupNormalMenuController];
}

- (void)longPressGestureRecognizerHandle:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state != UIGestureRecognizerStateBegan || ![self becomeFirstResponder])
        return;
    
    UIMenuItem *copy = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"copy", @"LCIMKitString", @"复制文本消息") action:@selector(copied:)];
    UIMenuItem *transpond = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"transpond", @"LCIMKitString", @"转发") action:@selector(transpond:)];
    UIMenuItem *favorites = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"favorites", @"LCIMKitString", @"收藏") action:@selector(favorites:)];
    UIMenuItem *more = [[UIMenuItem alloc] initWithTitle:NSLocalizedStringFromTable(@"more", @"LCIMKitString", @"更多") action:@selector(more:)];
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    switch (self.messageBubbleView.message.messageMediaType) {
        case XHBubbleMessageMediaTypeText:
        case XHBubbleMessageMediaTypePhoto:
        case XHBubbleMessageMediaTypeLocalPosition:
            [menu setMenuItems:[NSArray arrayWithObjects:copy, transpond, favorites, more, nil]];
            break;
        case XHBubbleMessageMediaTypeEmotion:
        case XHBubbleMessageMediaTypeVideo:
        case XHBubbleMessageMediaTypeVoice:
            [menu setMenuItems:[NSArray arrayWithObjects:transpond, favorites, more, nil]];
            break;
    }
    
    CGRect targetRect = [self convertRect:[self.messageBubbleView bubbleFrame]
                                 fromView:self.messageBubbleView];
    
    [menu setTargetRect:CGRectInset(targetRect, 0.0f, 4.0f) inView:self];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMenuWillShowNotification:)
                                                 name:UIMenuControllerWillShowMenuNotification
                                               object:nil];
    [menu setMenuVisible:YES animated:YES];
}

- (void)sigleTapGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self setupNormalMenuController];
        if ([self.delegate respondsToSelector:@selector(multiMediaMessageDidSelectedOnMessage:atIndexPath:onMessageTableViewCell:)]) {
            [self.delegate multiMediaMessageDidSelectedOnMessage:self.messageBubbleView.message atIndexPath:self.indexPath onMessageTableViewCell:self];
        }
    }
}

- (void)doubleTapGestureRecognizerHandle:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.delegate respondsToSelector:@selector(didDoubleSelectedOnTextMessage:atIndexPath:)]) {
            [self.delegate didDoubleSelectedOnTextMessage:self.messageBubbleView.message atIndexPath:self.indexPath];
        }
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

#pragma mark - Getters

- (XHBubbleMessageType)bubbleMessageType {
    return self.messageBubbleView.message.bubbleMessageType;
}

+ (CGFloat)calculateCellHeightWithMessage:(id<XHMessageModel>)message
                        displaysTimestamp:(BOOL)displayTimestamp
                         displaysPeerName:(BOOL)displayPeerName {
    //kXHLabelPadding是时间 Label 上下的间距，上下都是kXHLabelPadding大
    CGFloat timestampHeight = kTimeStampZoneHeight(displayTimestamp);
    CGFloat avatorHeight = kXHAvatorImageSize;
    //subviewHeights指的就是时间 Label 和它的间距，如果没有时间 Label，还是要保留相同大小的一条间隙
    CGFloat subviewHeights = timestampHeight + kXHBubbleMessageViewBottomPadding;
    // kXHBubbleMessageViewPadding 是气泡上下的间距，上下都是kXHBubbleMessageViewPadding大
    
    CGFloat bubbleHeight = [XHMessageBubbleView calculateCellHeightWithMessage:message] + kXHBubbleMessageViewTopPadding;
    switch (message.bubbleMessageType) {
        case XHBubbleMessageTypeReceiving:
            break;
        case XHBubbleMessageTypeSending:
            displayPeerName = NO;
            break;
    }
    return subviewHeights + MAX(avatorHeight, bubbleHeight + kPeerNameZoneHeight(displayPeerName));
}

#pragma mark - Life cycle


- (void)setup {

    self.backgroundColor = [UIColor whiteColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerHandle:)];
    [recognizer setMinimumPressDuration:0.4f];
    [self addGestureRecognizer:recognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerHandle:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (instancetype)initWithMessage:(id<XHMessageModel>)message
                reuseIdentifier:(NSString *)theCellIdentifier {
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:theCellIdentifier];
    if (self) {
        // 如果初始化成功，那就根据Message类型进行初始化控件，比如配置头像，配置发送和接收的样式
        // 1、是否显示Time Line的label
        if (!_timestampLabel) {
            LKBadgeView *timestampLabel = [[LKBadgeView alloc] initWithFrame:CGRectMake(0, kXHLabelPadding, [UIScreen mainScreen].bounds.size.width, kXHTimeStampLabelHeight)];
            timestampLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
            timestampLabel.badgeColor = [UIColor colorWithRed:195.f /255.f green:195.f /255.f blue:195.f /255.f alpha:1.f];
            timestampLabel.textColor = [UIColor whiteColor];
            timestampLabel.font = [UIFont systemFontOfSize:13.0f];
            timestampLabel.center = CGPointMake(CGRectGetWidth([[UIScreen mainScreen] bounds]) / 2.0, timestampLabel.center.y);
            [self.contentView addSubview:timestampLabel];
            [self.contentView bringSubviewToFront:timestampLabel];
            _timestampLabel = timestampLabel;
        }
        
        // 2、配置头像
        // avator
        if(!_avatorButton){
            CGRect avatorButtonFrame;
            switch (message.bubbleMessageType) {
                case XHBubbleMessageTypeReceiving:
                    avatorButtonFrame = CGRectMake(kXHAvatorPaddingX, kXHAvatorPaddingY +kXHTimeStampLabelHeight, kXHAvatorImageSize, kXHAvatorImageSize);
                    break;
                case XHBubbleMessageTypeSending:
                    avatorButtonFrame = CGRectMake(CGRectGetWidth(self.bounds) - kXHAvatorImageSize - kXHAvatorPaddingX, kXHAvatorPaddingY + kXHTimeStampLabelHeight, kXHAvatorImageSize, kXHAvatorImageSize);
                    break;
            }
            
            UIButton *avatorButton = [[UIButton alloc] initWithFrame:avatorButtonFrame];
            NSString *imageName = @"Placeholder_Avator";
            NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
            UIImage *avatorImage = [UIImage imageNamed:imageNameWithBundlePath];
            
            [avatorButton setImage:[XHMessageAvatorFactory avatorImageNamed:avatorImage messageAvatorType:XHMessageAvatorTypeCircle] forState:UIControlStateNormal];
            [avatorButton addTarget:self action:@selector(avatorButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:avatorButton];
            self.avatorButton = avatorButton;
        }
        
        // 3、配置用户名
        if (!_peerNameLabel) {
            CGFloat userNameLableX = CGRectGetMaxX(self.avatorButton.frame) + kXHAvatorPaddingX;
            CGFloat offsetX = kXHAvatorPaddingX;
            UILabel *peerNameLabel;
            peerNameLabel.textAlignment = NSTextAlignmentLeft;
            CGRect frame = CGRectMake(userNameLableX,
                                      CGRectGetMinY(self.avatorButton.frame),
                                      self.contentView.frame.size.width - userNameLableX - offsetX,
                                      kXHPeerNameLabelHeight);
            peerNameLabel = [[UILabel alloc] initWithFrame:frame];
            peerNameLabel.backgroundColor = [UIColor clearColor];
            peerNameLabel.font = [UIFont systemFontOfSize:12];
            UIColor *color = [UIColor colorWithRed:(87) / 255.f green:(87) / 255.f blue:(87) / 255.f alpha:1.0f];
            peerNameLabel.textColor = color;
            [self.contentView addSubview:peerNameLabel];
            self.peerNameLabel = peerNameLabel;
        }
        
        // 4、配置需要显示什么消息内容，比如语音、文字、视频、图片
        if (!_messageBubbleView) {
            CGFloat bubbleX = 0.0f;
            CGFloat offsetX = 0.0f;
            if (message.bubbleMessageType == XHBubbleMessageTypeReceiving) {
                bubbleX = kXHAvatorImageSize + 2 * kXHAvatorPaddingX;
            } else {
                offsetX = kXHAvatorImageSize + 2 * kXHAvatorPaddingX;
            }
            
            CGFloat bubbleViewHeight = [XHMessageBubbleView calculateCellHeightWithMessage:message];
            CGFloat bubbleViewY;
            if ([theCellIdentifier isEqualToString:senderCellIdentifier]) {
                bubbleViewY = CGRectGetMinY(self.avatorButton.frame) + kXHBubbleMessageViewTopPadding + kXHPeerNameLabelHeight;
            } else {
                bubbleViewY = CGRectGetMinY(self.avatorButton.frame) + kXHBubbleMessageViewTopPadding;
            }
            CGRect frame = CGRectMake(bubbleX,
                                      bubbleViewY,
                                      self.contentView.frame.size.width - bubbleX - offsetX,
                                      bubbleViewHeight);
            
            // bubble container
            XHMessageBubbleView *messageBubbleView = [[XHMessageBubbleView alloc] initWithFrame:frame message:message];
            messageBubbleView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                                  | UIViewAutoresizingFlexibleHeight
                                                  | UIViewAutoresizingFlexibleBottomMargin);
            [self.contentView addSubview:messageBubbleView];
            [self.contentView sendSubviewToBack:messageBubbleView];
            self.messageBubbleView = messageBubbleView;
        }
        
        if(!self.statusView){
            //TODO:
            CGRect statusViewFrame=CGRectMake(0, 0, kXHStatusViewWidth, kXHStatusViewHeight);
            XHMessageStatusView *statusView=[[XHMessageStatusView alloc] initWithFrame:statusViewFrame];
            //attributedLabel.backgroundColor=[UIColor redColor];
            [self.contentView addSubview:statusView];
            [self.contentView bringSubviewToFront:statusView];
            [statusView.retryButton addTarget:self action:@selector(retryButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            self.statusView = statusView;
        }
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    // Initialization code
    [self setup];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat layoutOriginY = kTimeStampZoneHeight(self.displayTimestamp);
    CGRect avatorButtonFrame = self.avatorButton.frame;
    avatorButtonFrame.origin.y = layoutOriginY;
    avatorButtonFrame.origin.x = ([self bubbleMessageType] == XHBubbleMessageTypeReceiving) ? kXHAvatorPaddingX : ((CGRectGetWidth(self.bounds) - kXHAvatorPaddingX - kXHAvatorImageSize));
    self.avatorButton.frame = avatorButtonFrame;

    CGFloat bubbleViewY = CGRectGetMinY(avatorButtonFrame) + kXHBubbleMessageViewTopPadding;
    if ([self bubbleMessageType] == XHBubbleMessageTypeReceiving) {
        bubbleViewY += kPeerNameZoneHeight(self.displayPeerName);
    }
    CGFloat bubbleViewHeight = [XHMessageBubbleView calculateCellHeightWithMessage:self.messageBubbleView.message];

    CGFloat userNameLableX = CGRectGetMaxX(self.avatorButton.frame) + kXHAvatorPaddingX;
    CGFloat offsetX = kXHAvatorPaddingX;
    CGRect peerNameLabelFrame = CGRectMake(userNameLableX,
                                           CGRectGetMinY(self.avatorButton.frame),
                                           self.contentView.frame.size.width - userNameLableX - offsetX,
                                           kXHPeerNameLabelHeight);
    
    CGRect bubbleMessageViewFrame = self.messageBubbleView.frame;
    bubbleMessageViewFrame.origin.y = bubbleViewY;
    
    CGFloat bubbleX = 0.0f;
    if ([self bubbleMessageType] == XHBubbleMessageTypeReceiving) {
        bubbleX = kXHAvatorImageSize + kXHAvatorPaddingX + kXHAvatorPaddingX;
    }
    bubbleMessageViewFrame.origin.x = bubbleX;
    bubbleMessageViewFrame.size.height = bubbleViewHeight;
    
    self.peerNameLabel.frame = peerNameLabelFrame;
    self.messageBubbleView.frame = bubbleMessageViewFrame;
    
    if(self.bubbleMessageType==XHBubbleMessageTypeSending){
        self.statusView.hidden=NO;
        CGFloat statusX=CGRectGetMinX(self.messageBubbleView.bubbleFrame)-kXHStatusViewWidth-3;
        CGFloat halfH=self.messageBubbleView.bubbleFrame.size.height/2;
        CGRect statusFrame=self.statusView.frame;
        statusFrame.origin.y=layoutOriginY+halfH;
        if([self.messageBubbleView.message messageMediaType]==XHBubbleMessageMediaTypeVoice && self.messageBubbleView.message.voiceDuration!=0){
            statusX=statusX-15;
        }
        statusFrame.origin.x=statusX;
        self.statusView.frame=statusFrame;
    } else {
        self.statusView.hidden=YES;
    }
    
#ifdef LCIMDebugging
    //【debugging】：只有当 LCIMDebugging 值为1时，才执行从这里到#else之间的代码
    self.messageBubbleView.backgroundColor = [UIColor blackColor];
    self.avatorButton.backgroundColor = [UIColor redColor];
    self.peerNameLabel.backgroundColor = [UIColor greenColor];
    self.backgroundColor = [UIColor yellowColor];
    self.statusView.backgroundColor = [UIColor blueColor];
#endif

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TableViewCell

- (void)prepareForReuse {
    // 这里做清除工作
    [super prepareForReuse];
    self.messageBubbleView.animationVoiceImageView.image = nil;
    self.messageBubbleView.displayTextView.text = nil;
    self.messageBubbleView.displayTextView.attributedText = nil;
    self.messageBubbleView.bubblePhotoImageView.messagePhoto = nil;
    self.messageBubbleView.emotionImageView.animatedImage = nil;
    self.timestampLabel.text = nil;
}

@end
