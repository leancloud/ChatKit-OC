//
//  XMNChatLocationMessageCell.m
//  XMNChatExample
//
//  Created by shscce on 15/11/17.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNChatLocationMessageCell.h"

#import "Masonry.h"

@interface XMNChatLocationMessageCell ()

@property (nonatomic, strong) UIImageView *locationIV;
@property (nonatomic, strong) UILabel *locationAddressL;

@end

@implementation XMNChatLocationMessageCell

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    
    [self.locationIV mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.messageContentV.mas_left).with.offset(16);
        make.top.equalTo(self.messageContentV.mas_top).with.offset(8);
        make.bottom.equalTo(self.messageContentV.mas_bottom).with.offset(-8);
        make.width.equalTo(@60);
        make.height.equalTo(@60);
    }];
    
    [self.locationAddressL mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.locationIV.mas_right).with.offset(8);
        make.top.equalTo(self.locationIV.mas_top);
        make.right.equalTo(self.messageContentV.mas_right).with.offset(-16);
//        make.bottom.equalTo(self.messageContentV.mas_bottom).with.offset(-8);
    }];
    
}

#pragma mark - Public Methods

- (void)setup {
    
    [self.messageContentV addSubview:self.locationIV];
    [self.messageContentV addSubview:self.locationAddressL];
    [super setup];
    
}

- (void)configureCellWithData:(id)data {
    [super configureCellWithData:data];
    _locationAddressL.text=data[kXMNMessageConfigurationLocationKey];
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
        _locationIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"location"]];
    }
    return _locationIV;
}

@end
