//
//  LCIMSendImageView.m
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMSendImageView.h"

@interface LCIMSendImageView ()

@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;

@end

@implementation LCIMSendImageView

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
- (void)setMessageSendState:(LCIMMessageSendState)messageSendState {
    _messageSendState = messageSendState;
    if (_messageSendState == LCIMMessageSendStateSending) {
        dispatch_async(dispatch_get_main_queue(),^{
            if (!self.indicatorView.isAnimating) {
                [self.indicatorView startAnimating];
            }
        });
        self.indicatorView.hidden = NO;
    } else {
        dispatch_async(dispatch_get_main_queue(),^{
            if (self.indicatorView.isAnimating) {
                [self.indicatorView stopAnimating];
            }
        });
        self.indicatorView.hidden = YES;
    }
    
    switch (_messageSendState) {
        case LCIMMessageSendStateSending:
        case LCIMMessageSendStateFailed:
            self.hidden = NO;
            break;
        default:
            self.hidden = YES;
            break;
    }
}

@end
