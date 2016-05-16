//
//  LCIMChatVoiceMessageCell.m
//  LCIMChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMChatVoiceMessageCell.h"
#import "Masonry.h"
#import "LCIMMessageVoiceFactory.h"
#import "LCIMAVAudioPlayer.h"

@interface LCIMChatVoiceMessageCell ()

@property (nonatomic, strong) UIImageView *messageVoiceStatusImageView;
@property (nonatomic, strong) UILabel *messageVoiceSecondsLabel;
@property (nonatomic, strong) UIActivityIndicatorView *messageIndicatorView;

@end

@implementation LCIMChatVoiceMessageCell

#pragma mark - Override Methods

- (void)prepareForReuse {
    [super prepareForReuse];
    [self setVoiceMessageState:LCIMVoiceMessageStateNormal];
}

- (void)updateConstraints {
    [super updateConstraints];

    if (self.messageOwner == LCIMMessageOwnerSelf) {
        [self.messageVoiceStatusImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.messageContentView.mas_right).with.offset(-12);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        [self.messageVoiceSecondsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.messageVoiceStatusImageView.mas_left).with.offset(-8);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        [self.messageIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.messageContentView);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
    } else if (self.messageOwner == LCIMMessageOwnerOther) {
        [self.messageVoiceStatusImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.messageContentView.mas_left).with.offset(12);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        
        [self.messageVoiceSecondsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.messageVoiceStatusImageView.mas_right).with.offset(8);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        [self.messageIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.messageContentView);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
    }
    
    [self.messageContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_greaterThanOrEqualTo(@(80)).priorityHigh();
    }];

}

#pragma mark - Public Methods

- (void)setup {
    [self.messageContentView addSubview:self.messageVoiceSecondsLabel];
    [self.messageContentView addSubview:self.messageVoiceStatusImageView];
    [self.messageContentView addSubview:self.messageIndicatorView];
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapMessageImageViewGestureRecognizerHandler:)];
    [self.messageContentView addGestureRecognizer:recognizer];
    [super setup];
    self.voiceMessageState = LCIMVoiceMessageStateNormal;
}

- (void)singleTapMessageImageViewGestureRecognizerHandler:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.delegate respondsToSelector:@selector(messageCellTappedMessage:)]) {
            [self.delegate messageCellTappedMessage:self];
        }
    }
}

- (void)configureCellWithData:(LCIMMessage *)message {
    [super configureCellWithData:message];
    self.messageVoiceSecondsLabel.text = [NSString stringWithFormat:@"%@''",message.voiceDuration];
    CGFloat voiceDuration = [message.voiceDuration floatValue];
    if (voiceDuration > 2) {
        __block CGFloat length;
        CGFloat lengthUnit = 10.f;
        // 1-2 长度固定, 2-10s每秒增加一个单位, 10-60s每10s增加一个单位
        do {
            if (voiceDuration <= 10) {
                length = lengthUnit*(voiceDuration-2);
                break;
            }
            if (voiceDuration > 10) {
                length = lengthUnit*(10-2) + lengthUnit*((voiceDuration-2)/10);
                break;
            }
        } while (NO);
        [self.messageContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(80+length));
        }];
    } else {
        [self.messageContentView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(80));
        }];
    }
}

#pragma mark - Getters

- (UIImageView *)messageVoiceStatusImageView {
    if (!_messageVoiceStatusImageView) {
       _messageVoiceStatusImageView = [LCIMMessageVoiceFactory messageVoiceAnimationImageViewWithBubbleMessageType:self.messageOwner];
    }
    return _messageVoiceStatusImageView;
}

- (UILabel *)messageVoiceSecondsLabel {
    if (!_messageVoiceSecondsLabel) {
        _messageVoiceSecondsLabel = [[UILabel alloc] init];
        _messageVoiceSecondsLabel.font = [UIFont systemFontOfSize:14.0f];
        _messageVoiceSecondsLabel.text = @"0''";
    }
    return _messageVoiceSecondsLabel;
}

- (UIActivityIndicatorView *)messageIndicatorView {
    if (!_messageIndicatorView) {
        _messageIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _messageIndicatorView;
}

#pragma mark - Setters

- (void)setVoiceMessageState:(LCIMVoiceMessageState)voiceMessageState {
    if (_voiceMessageState != voiceMessageState) {
        _voiceMessageState = voiceMessageState;
    }
    self.messageVoiceSecondsLabel.hidden = NO;
    self.messageVoiceStatusImageView.hidden = NO;
    self.messageIndicatorView.hidden = YES;
    [self.messageIndicatorView stopAnimating];
    
    if (_voiceMessageState == LCIMVoiceMessageStatePlaying) {
        self.messageVoiceStatusImageView.highlighted = YES;
        [self.messageVoiceStatusImageView startAnimating];
    } else if (_voiceMessageState == LCIMVoiceMessageStateDownloading) {
        self.messageVoiceSecondsLabel.hidden = YES;
        self.messageVoiceStatusImageView.hidden = YES;
        self.messageIndicatorView.hidden = NO;
        [self.messageIndicatorView startAnimating];
    } else {
        self.messageVoiceStatusImageView.highlighted = NO;
        [self.messageVoiceStatusImageView stopAnimating];
    }
}

@end
