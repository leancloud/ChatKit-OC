//
//  XMNChatImageMessageCell.m
//  XMNChatExample
//
//  Created by shscce on 15/11/16.
//  Copyright © 2015年 xmfraker. All rights reserved.
//

#import "XMNChatImageMessageCell.h"

#import "Masonry.h"

@interface XMNChatImageMessageCell ()

/**
 *  用来显示image的UIImageView
 */
@property (nonatomic, strong) UIImageView *messageImageView;

/**
 *  用来显示上传进度的UIView
 */
@property (nonatomic, strong) UIView *messageProgressView;

/**
 *  显示上传进度百分比的UILabel
 */
@property (nonatomic, weak) UILabel *messageProgressLabel;

@end

@implementation XMNChatImageMessageCell

#pragma mark - Override Methods

- (void)updateConstraints {

    [super updateConstraints];
    [self.messageImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentV);
        make.height.lessThanOrEqualTo(@200);
    }];

}

#pragma mark - Public Methods

- (void)setup {
    
    [self.messageContentV addSubview:self.messageImageView];
    [self.messageContentV addSubview:self.messageProgressView];
    [super setup];
    
}

- (void)configureCellWithData:(id)data {
    
    [super configureCellWithData:data];
    id image = data[kXMNMessageConfigurationImageKey];
    if ([image isKindOfClass:[UIImage class]]) {
        self.messageImageView.image = image;
    }else if ([image isKindOfClass:[NSString class]]) {
        //TODO 是一个路径,可能是网址,需要加载
        NSLog(@"是一个路径");
    }else {
        NSLog(@"未知的图片类型");
    }
    

}


#pragma mark - Setters

- (void)setUploadProgress:(CGFloat)uploadProgress {
    [self setMessageSendState:XMNMessageSendStateSending];
    [self.messageProgressView setFrame:CGRectMake(0, 0, self.messageImageView.bounds.size.width, self.messageImageView.bounds.size.height * (1 - uploadProgress))];
    [self.messageProgressLabel setText:[NSString stringWithFormat:@"%.0f%%",uploadProgress * 100]];
}

- (void)setMessageSendState:(XMNMessageSendState)messageSendState {
    [super setMessageSendState:messageSendState];
    if (messageSendState == XMNMessageSendStateSending) {
        if (!self.messageProgressView.superview) {
            [self.messageContentV addSubview:self.messageProgressView];
        }
        [self.messageProgressLabel setFrame:CGRectMake(0, self.messageImageView.bounds.size.height/2 - 8, self.messageImageView.bounds.size.width, 16)];
    }else {
        [self.messageProgressView removeFromSuperview];
    }
    
}

#pragma mark - Getters

- (UIImageView *)messageImageView {
    
    if (!_messageImageView) {
        _messageImageView = [[UIImageView alloc] init];
        _messageImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _messageImageView;
    
}

- (UIView *)messageProgressView {
    if (!_messageProgressView) {
        _messageProgressView = [[UIView alloc] init];
        _messageProgressView.backgroundColor = [UIColor colorWithRed:.0f green:.0f blue:.0f alpha:.3f];
        _messageProgressView.translatesAutoresizingMaskIntoConstraints = NO;
        _messageProgressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        UILabel *progressLabel = [[UILabel alloc] init];
        progressLabel.font = [UIFont systemFontOfSize:14.0f];
        progressLabel.textColor = [UIColor whiteColor];
        progressLabel.textAlignment = NSTextAlignmentCenter;
        progressLabel.text = @"50.0%";
        
        [_messageProgressView addSubview:self.messageProgressLabel = progressLabel];
    }
    return _messageProgressView;
}

@end
