//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "LCCKSettingHeaderTitleView.h"
#import "UIFont+LCCKExtension.h"
//#import <Masonry/Masonry.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
@implementation LCCKSettingHeaderTitleView

- (id) initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        [self.contentView addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.contentView).mas_offset(15);
            make.right.mas_equalTo(self.contentView).mas_offset(-15);
            make.bottom.mas_equalTo(self.contentView).mas_offset(-5.0f);
        }];
    }
    return self;
}

- (void) setText:(NSString *)text {
    _text = text;
    [self.titleLabel setText:text];
}

#pragma mark - Getter
- (UILabel *) titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        [_titleLabel setTextColor:[UIColor grayColor]];
        [_titleLabel setFont:[UIFont lcck_fontSettingHeaderAndFooterTitle]];
        [_titleLabel setNumberOfLines:0];
    }
    return _titleLabel;
}

@end
