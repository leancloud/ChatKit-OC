//
//  XMNSendImageView.m
//  XMChatBarExample
//
//  Created by shscce on 15/11/23.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNSendImageView.h"

@interface XMNSendImageView ()

@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;

@end

@implementation XMNSendImageView

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
- (void)setMessageSendState:(XMNMessageSendState)messageSendState {
    _messageSendState = messageSendState;
    if (_messageSendState == XMNMessageSendStateSending) {
        [self.indicatorView startAnimating];
        self.indicatorView.hidden = NO;
    }else {
        [self.indicatorView stopAnimating];
        self.indicatorView.hidden = YES;
    }

    switch (_messageSendState) {
        case XMNMessageSendStateSending:
        case XMNMessageSendFail:
            self.hidden = NO;
            break;
        default:
            self.hidden = YES;
            break;
    }
}

@end
