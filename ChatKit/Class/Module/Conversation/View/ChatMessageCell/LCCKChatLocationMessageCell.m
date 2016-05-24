//
//  LCCKChatLocationMessageCell.m
//  LCCKChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/17.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatLocationMessageCell.h"
#import "Masonry.h"
#import "UIImage+LCCKExtension.h"

@interface LCCKChatLocationMessageCell ()

@property (nonatomic, strong) UIImageView *locationImageView;
@property (nonatomic, strong) UILabel *locationAddressLabel;

@end

@implementation LCCKChatLocationMessageCell

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    
    [self.locationImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.messageContentView.mas_left).with.offset(16);
        make.top.equalTo(self.messageContentView.mas_top).with.offset(8);
        make.bottom.equalTo(self.messageContentView.mas_bottom).with.offset(-8);
        make.width.equalTo(@60);
        make.height.equalTo(@60);
    }];
    
    [self.locationAddressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.locationImageView.mas_right).with.offset(8);
        make.top.equalTo(self.locationImageView.mas_top);
        make.right.equalTo(self.messageContentView.mas_right).with.offset(-16);
        //        make.bottom.equalTo(self.messageContentView.mas_bottom).with.offset(-8);
    }];
    
}

#pragma mark - Public Methods

- (void)setup {
    [self.messageContentView addSubview:self.locationImageView];
    [self.messageContentView addSubview:self.locationAddressLabel];
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapMessageImageViewGestureRecognizerHandler:)];
    [self.messageContentView addGestureRecognizer:recognizer];
    [super setup];
    
}

- (void)singleTapMessageImageViewGestureRecognizerHandler:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.delegate respondsToSelector:@selector(messageCellTappedMessage:)]) {
            [self.delegate messageCellTappedMessage:self];
        }
    }
}


- (void)configureCellWithData:(LCCKMessage *)message {
    [super configureCellWithData:message];
    _locationAddressLabel.text = message.geolocations;
}

#pragma mark - Getters

- (UILabel *)locationAddressLabel {
    if (!_locationAddressLabel) {
        _locationAddressLabel = [[UILabel alloc] init];
        _locationAddressLabel.textColor = [UIColor blackColor];
        _locationAddressLabel.font = [UIFont systemFontOfSize:16.0f];
        _locationAddressLabel.numberOfLines = 3;
        _locationAddressLabel.textAlignment = NSTextAlignmentNatural;
        _locationAddressLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _locationAddressLabel;
}

- (UIImageView *)locationImageView {
    if (!_locationImageView) {
        NSString *imageName;
        if (self.messageOwner == LCCKMessageOwnerSelf) {
            imageName = @"message_sender_location";
        } else {
            imageName = @"message_receiver_location";
        }
        _locationImageView = [[UIImageView alloc] initWithImage:({
            UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"MessageBubble" bundleForClass:[self class]];
            image;})
                              ];
    }
    return _locationImageView;
}

@end
