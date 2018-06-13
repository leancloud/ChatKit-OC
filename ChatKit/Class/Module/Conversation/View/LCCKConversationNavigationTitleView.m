//
//  LCCKConversationNavigationTitleView.m
//  Pods
//
//  v0.8.5 Created by ElonChan on 16/7/19.
//
//

#import "LCCKConversationNavigationTitleView.h"
#import "NSString+LCCKExtension.h"
#import "UIImageView+LCCKExtension.h"

#if __has_include(<CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>)
#import <CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>
#else
#import "CYLDeallocBlockExecutor.h"
#endif
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
static CGFloat const kLCCKTitleFontSize = 17.f;

static void * const LCCKConversationViewControllerMutedContext = (void*)&LCCKConversationViewControllerMutedContext;
static void * const LCCKConversationViewControllerNameContext = (void*)&LCCKConversationViewControllerNameContext;
static void * const LCCKConversationViewControllerMembersCountContext = (void*)&LCCKConversationViewControllerMembersCountContext;

@interface LCCKConversationNavigationTitleView ()

@property (nonatomic, strong) UILabel *conversationNameView;
@property (nonatomic, strong) UILabel *membersCountView;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, strong) UIStackView *containerView;
@property (nonatomic, strong) UIImageView *remindMuteImageView;
@property (nonatomic, copy) NSString *conversationName;
@property (nonatomic, strong) AVIMConversation *conversation;
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
    if(context == LCCKConversationViewControllerMutedContext) {
        id newKey = change[NSKeyValueChangeNewKey];
        BOOL muted = [newKey boolValue];
        self.remindMuteImageView.hidden = !muted;
        [self.containerView layoutIfNeeded];
    } else if(context == LCCKConversationViewControllerNameContext) {
        [self resetConversationNameWithMembersCountChanged:NO];
    } else if (context == LCCKConversationViewControllerMembersCountContext) {
        [self resetConversationName];
    }
}

- (instancetype)sharedInitWithConversation:(AVIMConversation *)conversation {
    [self addSubview:self.containerView];
    [conversation addObserver:self forKeyPath:@"muted" options:NSKeyValueObservingOptionNew context:LCCKConversationViewControllerMutedContext];
    [conversation addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:LCCKConversationViewControllerNameContext];
    [conversation addObserver:self forKeyPath:@"members.@count" options:NSKeyValueObservingOptionNew context:LCCKConversationViewControllerMembersCountContext];

    __unsafe_unretained __typeof(self) weakSelf = self;
    [self cyl_executeAtDealloc:^{
        [conversation removeObserver:weakSelf forKeyPath:@"muted"];
        [conversation removeObserver:weakSelf forKeyPath:@"name"];
        [conversation removeObserver:weakSelf forKeyPath:@"members.@count"];
    }];
    
    [self.containerView layoutIfNeeded];//fix member count view won't display when conversationNameView is too long
    return self;
}

- (instancetype)initWithConversation:(AVIMConversation *)conversation navigationController:(UINavigationController *)navigationController {
    if (self = [super init]) {
        _conversation = conversation;
        [self resetConversationName];
        [self setupWithNavigationController:navigationController];
        self.remindMuteImageView.hidden = !conversation.muted;
    }
    return self;
}

- (void)setupWithNavigationController:(UINavigationController *)navigationController {
    self.navigationController = navigationController;
    [self sharedInitWithConversation:self.conversation];
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
        _membersCountView = membersCountView;
    }
    return _membersCountView;
}

#pragma mark -
#pragma mark - Private Methods

- (void)resetConversationName {
    [self resetConversationNameWithMembersCountChanged:YES];
}

- (void)resetConversationNameWithMembersCountChanged:(BOOL)membersCountChanged {
    NSString *conversationName;
    if ([self.conversation.lcck_displayName lcck_containsString:@","]) {
        self.membersCountView.hidden = NO;
        conversationName = self.conversation.lcck_displayName;
    } else {
        self.membersCountView.hidden = YES;
        conversationName = self.conversation.lcck_title;
    }
    if (conversationName.length == 0 || !conversationName) {
        conversationName = LCCKLocalizedStrings(@"Chat");
    }
    self.conversationNameView.text = conversationName;
    if (membersCountChanged) {
        NSUInteger membersCount = self.conversation.members.count;
        self.membersCountView.text = [NSString stringWithFormat:@"(%@)", @(membersCount)];
    }
}

@end
