//
//  LCCKConversationNavigationTitleView.m
//  Pods
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/19.
//
//

#import "LCCKConversationNavigationTitleView.h"
#import "NSString+LCCKExtension.h"
#import "UIImageView+LCCKExtension.h"
#import "LCCKDeallocBlockExecutor.h"
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
static CGFloat const kLCCKTitleFontSize = 17.f;
static void * const LCCKConversationNavigationTitleViewShowRemindMuteImageViewContext = (void*)&LCCKConversationNavigationTitleViewShowRemindMuteImageViewContext;

@interface LCCKConversationNavigationTitleView ()

@property (nonatomic, strong) UILabel *conversationNameView;
@property (nonatomic, strong) UILabel *membersCountView;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, strong) UIStackView *containerView;
@property (nonatomic, strong) UIImageView *remindMuteImageView;

@end

@implementation LCCKConversationNavigationTitleView

- (UIStackView *)containerView {
    if (!_containerView) {
        UIStackView *containerView = [[UIStackView alloc] initWithFrame:CGRectZero];
        containerView.axis = UILayoutConstraintAxisHorizontal;
        containerView.distribution = UIStackViewDistributionFill;
        containerView.alignment = UIStackViewAlignmentCenter;
        
        containerView.frame = ({
            CGRect frame = containerView.frame;
            CGFloat containerViewHeight = self.navigationController.navigationBar.frame.size.height;
            CGFloat containerViewWidth = self.navigationController.navigationBar.frame.size.width - 130;
            frame.size.width = containerViewWidth;
            frame.size.height = containerViewHeight;
            frame;
        });
        [containerView addArrangedSubview:self.conversationNameView];
        [containerView addArrangedSubview:self.membersCountView];
        [containerView addArrangedSubview:self.remindMuteImageView];
        _containerView = containerView;
    }
    return _containerView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != LCCKConversationNavigationTitleViewShowRemindMuteImageViewContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCCKConversationNavigationTitleViewShowRemindMuteImageViewContext) {
        //if ([keyPath isEqualToString:@"showRemindMuteImageView"]) {
        id newKey = change[NSKeyValueChangeNewKey];
        BOOL boolValue = [newKey boolValue];
        self.remindMuteImageView.hidden = !boolValue;
        [self.containerView layoutIfNeeded];//fix member count view won't display when conversationNameView is too long
    }
}

- (instancetype)sharedInit {
    [self addSubview:self.containerView];
    self.showRemindMuteImageView = NO;
    [self addObserver:self forKeyPath:@"showRemindMuteImageView" options:NSKeyValueObservingOptionNew context:LCCKConversationNavigationTitleViewShowRemindMuteImageViewContext];
    __unsafe_unretained typeof(self) weakSelf = self;
    [self lcck_executeAtDealloc:^{
        [weakSelf removeObserver:weakSelf forKeyPath:@"showRemindMuteImageView"];
    }];
    [self.containerView layoutIfNeeded];//fix member count view won't display when conversationNameView is too long
    return self;
}

- (instancetype)initWithConversation:(AVIMConversation *)conversation navigationController:(UINavigationController *)navigationController {
    if (self = [super init]) {
        CGFloat membersCount = conversation.members.count;
        NSString *conversationName;
        if ([conversation.lcck_displayName lcck_containsString:@","]) {
            self.membersCountView.hidden = NO;
            conversationName = conversation.lcck_displayName;
        } else {
            conversationName = conversation.lcck_title;
        }
        [self setupWithConversationName:conversationName membersCount:membersCount navigationController:navigationController];
        self.remindMuteImageView.hidden = !conversation.muted;
    }
    return self;
}

- (void)setupWithConversationName:(NSString *)conversationName membersCount:(NSInteger)membersCount navigationController:(UINavigationController *)navigationController {
    self.conversationNameView.text = conversationName;
    self.membersCountView.text = [NSString stringWithFormat:@"(%@)", @(membersCount)];
    self.navigationController = navigationController;
    [self sharedInit];
}

- (UIImageView *)remindMuteImageView {
    if (_remindMuteImageView == nil) {
        UIImageView *remindMuteImageView = [[UIImageView alloc] init];
        NSString *remindMuteImageName = @"Connectkeyboad_banner_mute";
        UIImage *remindMuteImage = [UIImage lcck_imageNamed:remindMuteImageName bundleName:@"Other" bundleForClass:[LCChatKit class]];
        remindMuteImageView.contentMode = UIViewContentModeScaleAspectFill;
        remindMuteImageView.image = remindMuteImage;
        remindMuteImageView.hidden = YES;
        [remindMuteImageView sizeToFit];
        _remindMuteImageView = remindMuteImageView;
    }
    return _remindMuteImageView;
}

- (UILabel *)conversationNameView {
    if (!_conversationNameView) {
        UILabel *conversationNameView = [[UILabel alloc] initWithFrame:CGRectZero];
        conversationNameView.font = [UIFont boldSystemFontOfSize:kLCCKTitleFontSize];
        conversationNameView.textColor = [UIColor whiteColor];
        //        conversationNameView.backgroundColor = [UIColor redColor];
        conversationNameView.textAlignment = NSTextAlignmentCenter;
        [conversationNameView sizeToFit];
        conversationNameView.lineBreakMode = NSLineBreakByTruncatingTail;
        _conversationNameView = conversationNameView;
    }
    return _conversationNameView;
}

- (UILabel *)membersCountView {
    if (!_membersCountView) {
        UILabel *membersCountView = [[UILabel alloc] initWithFrame:CGRectZero];
        membersCountView.font = [UIFont boldSystemFontOfSize:kLCCKTitleFontSize];
        membersCountView.textColor = [UIColor whiteColor];
        membersCountView.textAlignment = NSTextAlignmentCenter;
        [membersCountView sizeToFit];
        membersCountView.hidden = YES;
//        membersCountView.backgroundColor = [UIColor blueColor];
        _membersCountView = membersCountView;
    }
    return _membersCountView;
}

@end
