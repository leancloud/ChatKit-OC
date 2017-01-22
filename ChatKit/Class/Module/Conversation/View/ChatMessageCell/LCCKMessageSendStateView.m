//
//  LCCKMessageSendStateView.m
//  LCCKChatBarExample
//
//  v0.8.5 Created by ElonChan (wechat:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKMessageSendStateView.h"
#import "UIImage+LCCKExtension.h"

#if __has_include(<CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>)
#import <CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>
#else
#import "CYLDeallocBlockExecutor.h"
#endif

static void * const LCCKSendImageViewShouldShowIndicatorViewContext = (void*)&LCCKSendImageViewShouldShowIndicatorViewContext;

@interface LCCKMessageSendStateView ()

@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
@property (nonatomic, assign, getter=shouldShowIndicatorView) BOOL showIndicatorView;
@property (nonatomic, weak) UILabel *statusLabel;

@end

@implementation LCCKMessageSendStateView

- (instancetype)init {
    if (self = [super init]) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicatorView.hidden = YES;
        [self addSubview:self.indicatorView = indicatorView];
        [self statusLabel];
        // KVO注册监听
        [self addObserver:self forKeyPath:@"showIndicatorView" options:NSKeyValueObservingOptionNew context:LCCKSendImageViewShouldShowIndicatorViewContext];
        __unsafe_unretained __typeof(self) weakSelf = self;
        [self cyl_executeAtDealloc:^{
            [weakSelf removeObserver:weakSelf forKeyPath:@"showIndicatorView"];
        }];
        [self addTarget:self action:@selector(failImageViewTap:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return self;
}

- (UILabel *)statusLabel {
    if (_statusLabel) {
        return _statusLabel;
    }
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor redColor];
    label.text = @"read";
    label.font= [UIFont boldSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    [label sizeToFit];
    label.layer.cornerRadius = 3.0;
    label.clipsToBounds = YES;
    [self addSubview:_statusLabel = label];
    return _statusLabel;
}

- (void)showErrorIcon:(BOOL)showErrorIcon {
    if (showErrorIcon) {
        NSString *imageName = @"MessageSendFail";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
        [self setImage:image forState:UIControlStateNormal];
        self.userInteractionEnabled = YES;
    } else {
        [self setImage:nil forState:UIControlStateNormal];
        self.userInteractionEnabled = NO;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.indicatorView.frame = self.bounds;
    self.statusLabel.center = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
}

#pragma mark - Setters
- (void)setMessageSendState:(LCCKMessageSendState)messageSendState {
    _messageSendState = messageSendState;
    if (_messageSendState == LCCKMessageSendStateSending) {
        dispatch_async(dispatch_get_main_queue(),^{
            [self.indicatorView startAnimating];
        });
        self.showIndicatorView = YES;
    } else {
        dispatch_async(dispatch_get_main_queue(),^{
            [self.indicatorView stopAnimating];
        });
        self.showIndicatorView = NO;
    }
    
    switch (_messageSendState) {
        case LCCKMessageSendStateSending:
            self.showIndicatorView = YES;
            break;
            
            
        case LCCKMessageSendStateDelivered:
            self.showIndicatorView = NO;
            [self showErrorIcon:NO];
            self.statusLabel.text = LCCKLocalizedStrings(@"Delivered");
            break;
            
        case LCCKMessageSendStateFailed:
            self.showIndicatorView = NO;
            [self showErrorIcon:YES];
            self.statusLabel.hidden = YES;
            
            break;
            
        case LCCKMessageSendStateRead:
            self.showIndicatorView = NO;
            [self showErrorIcon:NO];
            self.statusLabel.text = LCCKLocalizedStrings(@"Read");
            break;
            
        case LCCKMessageSendStateNone:
        case LCCKMessageSendStateSent:
            self.hidden = YES;
            break;
    }
}

//- (void)setMessageSendState:(LCCKMessageSendState)messageSendState {
//    _messageSendState = messageSendState;
//    if (_messageSendState == LCCKMessageSendStateSending) {
//        dispatch_async(dispatch_get_main_queue(),^{
//            if (!self.indicatorView.isAnimating) {
//                [self.indicatorView startAnimating];
//            }
//        });
//        self.indicatorView.hidden = NO;
//    } else {
//        dispatch_async(dispatch_get_main_queue(),^{
//            if (self.indicatorView.isAnimating) {
//                [self.indicatorView stopAnimating];
//            }
//        });
//        self.indicatorView.hidden = YES;
//    }
//
//    switch (_messageSendState) {
//        case LCCKMessageSendStateSending:
//        case LCCKMessageSendStateFailed:
//            self.hidden = NO;
//            break;
//        default:
//            self.hidden = YES;
//            break;
//    }
//}

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != LCCKSendImageViewShouldShowIndicatorViewContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCCKSendImageViewShouldShowIndicatorViewContext) {
        if ([keyPath isEqualToString:@"showIndicatorView"]) {
            id newKey = change[NSKeyValueChangeNewKey];
            BOOL showIndicatorView = [newKey boolValue];
            self.hidden = NO;
            self.indicatorView.hidden = !showIndicatorView;

            if (showIndicatorView) {
                [self showErrorIcon:NO];
                self.statusLabel.hidden = YES;
            } else {
                //不显示指示器时，让 error 和 status 控件都默认展示，开发时只需要控制隐藏。
                [self showErrorIcon:YES];
                self.statusLabel.hidden = NO;
            }
        }
    }
}

- (void)failImageViewTap:(id)sender {
    if (self.shouldShowIndicatorView) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(resendMessage:)]) {
        [self.delegate resendMessage:self];
    }
}

@end
