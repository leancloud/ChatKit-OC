//
//  LCCKSendImageView.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKSendImageView.h"

@interface LCCKSendImageView ()

@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;

@end

@implementation LCCKSendImageView

- (instancetype)init {
    if ([super init]) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        indicatorView.hidden = YES;
        [self addSubview:self.indicatorView = indicatorView];
    }
    return self;
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
        self.indicatorView.hidden = NO;
    } else {
        dispatch_async(dispatch_get_main_queue(),^{
            [self.indicatorView stopAnimating];
        });
        self.indicatorView.hidden = YES;
    }
    
    switch (_messageSendState) {
        case LCCKMessageSendStateSending:
        case LCCKMessageSendStateFailed:
            self.hidden = NO;
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


@end
