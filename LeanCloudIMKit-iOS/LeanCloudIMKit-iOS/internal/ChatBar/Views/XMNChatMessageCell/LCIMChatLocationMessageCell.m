//
//  LCIMChatLocationMessageCell.m
//  LCIMChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/17.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMChatLocationMessageCell.h"

#import "Masonry.h"

@interface LCIMChatLocationMessageCell ()

@property (nonatomic, strong) UIImageView *locationIV;
@property (nonatomic, strong) UILabel *locationAddressL;

@end

@implementation LCIMChatLocationMessageCell

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    
    [self.locationIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.messageContentView.mas_left).with.offset(16);
        make.top.equalTo(self.messageContentView.mas_top).with.offset(8);
        make.bottom.equalTo(self.messageContentView.mas_bottom).with.offset(-8);
        make.width.equalTo(@60);
        make.height.equalTo(@60);
    }];
    
    [self.locationAddressL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.locationIV.mas_right).with.offset(8);
        make.top.equalTo(self.locationIV.mas_top);
        make.right.equalTo(self.messageContentView.mas_right).with.offset(-16);
        //        make.bottom.equalTo(self.messageContentView.mas_bottom).with.offset(-8);
    }];
    
}

#pragma mark - Public Methods

- (void)setup {
    
    [self.messageContentView addSubview:self.locationIV];
    [self.messageContentView addSubview:self.locationAddressL];
    [super setup];
    
}

- (void)configureCellWithData:(LCIMMessage *)message {
    [super configureCellWithData:message];
    _locationAddressL.text = message.geolocations;
}

#pragma mark - Getters

- (UILabel *)locationAddressL {
    if (!_locationAddressL) {
        _locationAddressL = [[UILabel alloc] init];
        _locationAddressL.textColor = [UIColor blackColor];
        _locationAddressL.font = [UIFont systemFontOfSize:16.0f];
        _locationAddressL.numberOfLines = 3;
        _locationAddressL.textAlignment = NSTextAlignmentNatural;
        _locationAddressL.lineBreakMode = NSLineBreakByTruncatingTail;
        _locationAddressL.text = @"上海市 试验费snap那就开动脑筋阿萨德你接啊三年级可 ";
    }
    return _locationAddressL;
}

- (UIImageView *)locationIV {
    if (!_locationIV) {
        _locationIV = [[UIImageView alloc] initWithImage:({
            NSString *imageName = @"MessageBubble_Location";
            NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"MessageBubble.bundle/%@", imageName];
            UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
            image;})
                       ];
    }
    return _locationIV;
}

@end
