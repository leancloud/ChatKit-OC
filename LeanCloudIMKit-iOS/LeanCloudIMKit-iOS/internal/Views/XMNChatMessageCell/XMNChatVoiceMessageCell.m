//
//  XMNChatVoiceMessageCell.m
//  XMNChatExample
//
//  Created by shscce on 15/11/16.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNChatVoiceMessageCell.h"
#import "Masonry.h"

@interface XMNChatVoiceMessageCell ()

@property (nonatomic, strong) UIImageView *messageVoiceStatusIV;
@property (nonatomic, strong) UILabel *messageVoiceSecondsL;
@property (nonatomic, strong) UIActivityIndicatorView *messageIndicatorV;

@end

@implementation XMNChatVoiceMessageCell

#pragma mark - Override Methods


- (void)prepareForReuse {

    [super prepareForReuse];
    [self setVoiceMessageState:XMNVoiceMessageStateNormal];
    
}

- (void)updateConstraints {
    [super updateConstraints];

    if (self.messageOwner == XMNMessageOwnerSelf) {
        [self.messageVoiceStatusIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.messageContentV.mas_right).with.offset(-12);
            make.centerY.equalTo(self.messageContentV.mas_centerY);
        }];
        [self.messageVoiceSecondsL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.messageVoiceStatusIV.mas_left).with.offset(-8);
            make.centerY.equalTo(self.messageContentV.mas_centerY);
        }];
        [self.messageIndicatorV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.messageContentV);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
    }else if (self.messageOwner == XMNMessageOwnerOther) {
        [self.messageVoiceStatusIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.messageContentV.mas_left).with.offset(12);
            make.centerY.equalTo(self.messageContentV.mas_centerY);
        }];
        
        [self.messageVoiceSecondsL mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.messageVoiceStatusIV.mas_right).with.offset(8);
            make.centerY.equalTo(self.messageContentV.mas_centerY);
        }];
        [self.messageIndicatorV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.messageContentV);
            make.width.equalTo(@10);
            make.height.equalTo(@10);
        }];
    }
    
    [self.messageContentV mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(80));
    }];

}

#pragma mark - Public Methods

- (void)setup {

    [self.messageContentV addSubview:self.messageVoiceSecondsL];
    [self.messageContentV addSubview:self.messageVoiceStatusIV];
    [self.messageContentV addSubview:self.messageIndicatorV];
    [super setup];
    self.voiceMessageState = XMNVoiceMessageStateNormal;
    
}

- (void)configureCellWithData:(id)data {
    [super configureCellWithData:data];
    self.messageVoiceSecondsL.text = [NSString stringWithFormat:@"%ld''",[data[kXMNMessageConfigurationVoiceSecondsKey] integerValue]];
}

#pragma mark - Getters

- (UIImageView *)messageVoiceStatusIV {
    if (!_messageVoiceStatusIV) {
        _messageVoiceStatusIV = [[UIImageView alloc] init];
        _messageVoiceStatusIV.image = self.messageOwner != XMNMessageOwnerSelf ? [UIImage imageNamed:@"message_voice_receiver_normal"] : [UIImage imageNamed:@"message_voice_sender_normal"];
        UIImage *image1 = [UIImage imageNamed:self.messageOwner == XMNMessageOwnerSelf ? @"message_voice_sender_playing_1" : @"message_voice_receiver_playing_1"];
        UIImage *image2 = [UIImage imageNamed:self.messageOwner == XMNMessageOwnerSelf ? @"message_voice_sender_playing_2" : @"message_voice_receiver_playing_2"];
        UIImage *image3 = [UIImage imageNamed:self.messageOwner == XMNMessageOwnerSelf ? @"message_voice_sender_playing_3" : @"message_voice_receiver_playing_3"];
        _messageVoiceStatusIV.highlightedAnimationImages = @[image1,image2,image3];
        _messageVoiceStatusIV.animationDuration = 1.5f;
        _messageVoiceStatusIV.animationRepeatCount = NSUIntegerMax;
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

- (void)setVoiceMessageState:(XMNVoiceMessageState)voiceMessageState {
    if (_voiceMessageState != voiceMessageState) {
        _voiceMessageState = voiceMessageState;
    }
    self.messageVoiceSecondsL.hidden = NO;
    self.messageVoiceStatusIV.hidden = NO;
    self.messageIndicatorV.hidden = YES;
    [self.messageIndicatorV stopAnimating];
    
    if (_voiceMessageState == XMNVoiceMessageStatePlaying) {
        self.messageVoiceStatusIV.highlighted = YES;
        [self.messageVoiceStatusIV startAnimating];
    }else if (_voiceMessageState == XMNVoiceMessageStateDownloading) {
        self.messageVoiceSecondsL.hidden = YES;
        self.messageVoiceStatusIV.hidden = YES;
        self.messageIndicatorV.hidden = NO;
        [self.messageIndicatorV startAnimating];
    }else {
        self.messageVoiceStatusIV.highlighted = NO;
        [self.messageVoiceStatusIV stopAnimating];
    }
}

@end
