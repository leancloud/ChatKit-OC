//
//  LCCKMessageSendStateView.m
//  LCCKChatBarExample
//
//  v0.7.19 Created by ElonChan (wechat:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKMessageSendStateView.h"
#import "UIImage+LCCKExtension.h"
#import "LCCKDeallocBlockExecutor.h"

static void * const LCCKSendImageViewShouldShowIndicatorViewContext = (void*)&LCCKSendImageViewShouldShowIndicatorViewContext;

@interface LCCKMessageSendStateView ()

@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
@property (nonatomic, assign, getter=shouldShowIndicatorView) BOOL showIndicatorView;

@end

@implementation LCCKMessageSendStateView

- (instancetype)init {
    if (self = [super init]) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicatorView.hidden = YES;
        [self addSubview:self.indicatorView = indicatorView];
        // KVO注册监听
        [self addObserver:self forKeyPath:@"showIndicatorView" options:NSKeyValueObservingOptionNew context:LCCKSendImageViewShouldShowIndicatorViewContext];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self lcck_executeAtDealloc:^{
            [weakSelf removeObserver:weakSelf forKeyPath:@"showIndicatorView"];
        }];
        [self addTarget:self action:@selector(failImageViewTap:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return self;
}

- (void)showErrorIcon:(BOOL)showErrorIcon {
    if (showErrorIcon) {
        NSString *imageName = @"MessageSendFail";
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
        [self setImage:image forState:UIControlStateNormal];
    } else {
        [self setImage:nil forState:UIControlStateNormal];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.indicatorView.frame = self.bounds;
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
            
        case LCCKMessageSendStateFailed:
            self.showIndicatorView = NO;
            break;
        default:
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
            if (showIndicatorView) {
                self.hidden = NO;
                self.indicatorView.hidden = NO;
                [self showErrorIcon:NO];
            } else {
                self.hidden = NO;
                self.indicatorView.hidden = YES;
                [self showErrorIcon:YES];
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
