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

@interface LCIMChatVoiceMessageCell ()

@property (nonatomic, strong) UIImageView *messageVoiceStatusIV;
@property (nonatomic, strong) UILabel *messageVoiceSecondsL;
@property (nonatomic, strong) UIActivityIndicatorView *messageIndicatorV;

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
        [self.messageVoiceStatusIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.messageContentView.mas_right).with.offset(-12);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        [self.messageVoiceSecondsL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.messageVoiceStatusIV.mas_left).with.offset(-8);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        [self.messageIndicatorV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.messageContentView);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
    } else if (self.messageOwner == LCIMMessageOwnerOther) {
        [self.messageVoiceStatusIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.messageContentView.mas_left).with.offset(12);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        
        [self.messageVoiceSecondsL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.messageVoiceStatusIV.mas_right).with.offset(8);
            make.centerY.equalTo(self.messageContentView.mas_centerY);
        }];
        [self.messageIndicatorV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.messageContentView);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
    }
    
    [self.messageContentView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(80));
    }];

}

#pragma mark - Public Methods

- (void)setup {
    [self.messageContentView addSubview:self.messageVoiceSecondsL];
    [self.messageContentView addSubview:self.messageVoiceStatusIV];
    [self.messageContentView addSubview:self.messageIndicatorV];
    [super setup];
    self.voiceMessageState = LCIMVoiceMessageStateNormal;
}

- (void)configureCellWithData:(LCIMMessage *)message {
    [super configureCellWithData:message];
    self.messageVoiceSecondsL.text = message.voiceDuration;
}

#pragma mark - Getters

- (UIImageView *)messageVoiceStatusIV {
    if (!_messageVoiceStatusIV) {
       _messageVoiceStatusIV = [LCIMMessageVoiceFactory messageVoiceAnimationImageViewWithBubbleMessageType:self.messageOwner];
    }
    return _messageVoiceStatusIV;
}

- (UILabel *)messageVoiceSecondsL {
    if (!_messageVoiceSecondsL) {
        _messageVoiceSecondsL = [[UILabel alloc] init];
        _messageVoiceSecondsL.font = [UIFont systemFontOfSize:14.0f];
        _messageVoiceSecondsL.text = @"0''";
    }
    return _messageVoiceSecondsL;
}

- (UIActivityIndicatorView *)messageIndicatorV {
    if (!_messageIndicatorV) {
        _messageIndicatorV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return _messageIndicatorV;
}

#pragma mark - Setters

- (void)setVoiceMessageState:(LCIMVoiceMessageState)voiceMessageState {
    if (_voiceMessageState != voiceMessageState) {
        _voiceMessageState = voiceMessageState;
    }
    self.messageVoiceSecondsL.hidden = NO;
    self.messageVoiceStatusIV.hidden = NO;
    self.messageIndicatorV.hidden = YES;
    [self.messageIndicatorV stopAnimating];
    
    if (_voiceMessageState == LCIMVoiceMessageStatePlaying) {
        self.messageVoiceStatusIV.highlighted = YES;
        [self.messageVoiceStatusIV startAnimating];
    } else if (_voiceMessageState == LCIMVoiceMessageStateDownloading) {
        self.messageVoiceSecondsL.hidden = YES;
        self.messageVoiceStatusIV.hidden = YES;
        self.messageIndicatorV.hidden = NO;
        [self.messageIndicatorV startAnimating];
    } else {
        self.messageVoiceStatusIV.highlighted = NO;
        [self.messageVoiceStatusIV stopAnimating];
    }
}

@end
