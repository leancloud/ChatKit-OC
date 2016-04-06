//
//  LCIMChatImageMessageCell.m
//  LCIMChatExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMChatImageMessageCell.h"
#import "Masonry.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface LCIMChatImageMessageCell ()

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

@implementation LCIMChatImageMessageCell

#pragma mark - Override Methods

- (void)updateConstraints {
    [super updateConstraints];
    [self.messageImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentView);
        make.height.mas_equalTo(@200);
        make.width.mas_equalTo(@200);
    }];
}

#pragma mark - Public Methods

- (void)setup {
    [self.messageContentView addSubview:self.messageImageView];
    [self.messageContentView addSubview:self.messageProgressView];
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
- (void)configureCellWithData:(LCIMMessage *)message {
    [super configureCellWithData:message];
    UIImage *image = message.photo;
    if (image) {
        self.messageImageView.image = image;
        return;
    }
    [self.messageImageView  sd_setImageWithURL:message.originPhotoURL placeholderImage:[self imageInBundleForImageName:@"Placeholder_Image"]
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                         if (error) {
                                             self.messageImageView.image = [self imageInBundleForImageName:@"Placeholder_Accept_Defeat"];
                                         }
                                     }
     ];
}

- (UIImage *)imageInBundleForImageName:(NSString *)imageName {
    return ({
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        image;});
}

#pragma mark - Setters

- (void)setUploadProgress:(CGFloat)uploadProgress {
    [self setMessageSendState:LCIMMessageSendStateSending];
    [self.messageProgressView setFrame:CGRectMake(0, 0, self.messageImageView.bounds.size.width, self.messageImageView.bounds.size.height * (1 - uploadProgress))];
    [self.messageProgressLabel setText:[NSString stringWithFormat:@"%.0f%%",uploadProgress * 100]];
}

- (void)setMessageSendState:(LCIMMessageSendState)messageSendState {
    [super setMessageSendState:messageSendState];
    if (messageSendState == LCIMMessageSendStateSending) {
        if (!self.messageProgressView.superview) {
            [self.messageContentView addSubview:self.messageProgressView];
        }
        [self.messageProgressLabel setFrame:CGRectMake(0, self.messageImageView.bounds.size.height/2 - 8, self.messageImageView.bounds.size.width, 16)];
    } else {
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
        progressLabel.text = @"0.0%";
        [_messageProgressView addSubview:self.messageProgressLabel = progressLabel];
    }
    return _messageProgressView;
}

-(void)prepareForReuse {
    [super prepareForReuse];
    self.messageProgressLabel.text = @"0.0%";
}

@end
