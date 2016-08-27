//
//  LCCKChatImageMessageCell.m
//  LCCKChatExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/16.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatImageMessageCell.h"
#import "UIImage+LCCKExtension.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
    #import <SDWebImage/UIImageView+WebCache.h>
#else
    #import "UIImageView+WebCache.h"
#endif

@interface LCCKChatImageMessageCell ()

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

@implementation LCCKChatImageMessageCell

#pragma mark - Override Methods

#pragma mark - Public Methods

- (void)setup {
    [self.messageContentView addSubview:self.messageImageView];
    [self.messageContentView addSubview:self.messageProgressView];
    UIEdgeInsets edgeMessageBubbleCustomize;
    if (self.messageOwner == LCCKMessageOwnerTypeSelf) {
        UIEdgeInsets rightEdgeMessageBubbleCustomize = [LCCKSettingService sharedInstance].rightHollowEdgeMessageBubbleCustomize;
        edgeMessageBubbleCustomize = rightEdgeMessageBubbleCustomize;
    } else {
        UIEdgeInsets leftEdgeMessageBubbleCustomize = [LCCKSettingService sharedInstance].leftHollowEdgeMessageBubbleCustomize;
        edgeMessageBubbleCustomize = leftEdgeMessageBubbleCustomize;
    }
    [self.messageImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.messageContentView).with.insets(edgeMessageBubbleCustomize);
        make.height.lessThanOrEqualTo(@200).priorityHigh();
    }];
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapMessageImageViewGestureRecognizerHandler:)];
    [self.messageContentView addGestureRecognizer:recognizer];
    [super setup];
    [self addGeneralView];
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
    UIImage *thumbnailPhoto = message.thumbnailPhoto;
    do {
        if (self.messageImageView.image && (self.messageImageView.image == thumbnailPhoto)) {
            break;
        }
        if (thumbnailPhoto) {
            self.messageImageView.image = thumbnailPhoto;
            break;
        }
        NSString *imageLocalPath = message.photoPath;
        BOOL isLocalPath = ![imageLocalPath hasPrefix:@"http"];
        //note: this will ignore contentMode.
        if (imageLocalPath && isLocalPath) {
            NSData *imageData = [NSData dataWithContentsOfFile:imageLocalPath];
            UIImage *image = [UIImage imageWithData:imageData];
            UIImage *resizedImage = [image lcck_imageByScalingAspectFill];
            self.messageImageView.image = resizedImage;
            message.photo = image;
            message.thumbnailPhoto = resizedImage;
            break;
        }

        // requied!
        if (message.originPhotoURL) {
            [self.messageImageView  sd_setImageWithURL:message.originPhotoURL placeholderImage:[self imageInBundleForImageName:@"Placeholder_Image"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 dispatch_async(dispatch_get_main_queue(),^{
                                                     if (image){
                                                         message.photo = image;
                                                         message.thumbnailPhoto = [image lcck_imageByScalingAspectFill];
                                                         if ([self.delegate respondsToSelector:@selector(fileMessageDidDownload:)]) {
                                                             [self.delegate fileMessageDidDownload:self];
                                                         }
                                                     }
                                                 });
                                                 
                                             }
             ];
            break;
        }
        
    } while (NO);
}

- (UIImage *)imageInBundleForImageName:(NSString *)imageName {
    return ({
        UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[self class]];
        image;});
}

#pragma mark - Setters

- (void)setUploadProgress:(CGFloat)uploadProgress {
    [self setMessageSendState:LCCKMessageSendStateSending];
    [self.messageProgressView setFrame:CGRectMake(0, 0, self.messageImageView.bounds.size.width, self.messageImageView.bounds.size.height * (1 - uploadProgress))];
    [self.messageProgressLabel setText:[NSString stringWithFormat:@"%.0f%%",uploadProgress * 100]];
}

- (void)setMessageSendState:(LCCKMessageSendState)messageSendState {
    [super setMessageSendState:messageSendState];
    if (messageSendState == LCCKMessageSendStateSending) {
        if (!self.messageProgressView.superview) {
            [self.messageContentView addSubview:self.messageProgressView];
        }
        [self.messageProgressLabel setFrame:CGRectMake(0, self.messageImageView.image.size.height/2 - 8, self.messageImageView.image.size.width, 16)];
    } else {
        [self removeProgressView];
    }
}

- (void)removeProgressView {
    [self.messageProgressView removeFromSuperview];
     [[self.messageProgressView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.messageProgressView = nil;
    self.messageProgressLabel = nil;
}

#pragma mark - Getters

- (UIImageView *)messageImageView {
    if (!_messageImageView) {
        _messageImageView = [[UIImageView alloc] init];
        //FIXME:这一行可以不需要
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
        [_messageProgressView addSubview:self.messageProgressLabel = progressLabel];
    }
    return _messageProgressView;
}

#pragma mark -
#pragma mark - LCCKChatMessageCellSubclassing Method

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeImage;
}

@end
