//
//  LCIMContactCell.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMContactCell.h"
#import "LCIMConstants.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface LCIMContactCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatorImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end

@implementation LCIMContactCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avatorImageView.layer.cornerRadius = CGRectGetHeight(self.avatorImageView.frame) * 0.5;
    self.avatorImageView.clipsToBounds = YES;
}

- (void)configureWithAvatorURL:(NSURL *)avatorURL title:(NSString *)title subtitle:(NSString *)subtitle {
    NSString *imageName = @"Placeholder_Avator";
    NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"Placeholder.bundle/%@", imageName];
    UIImage *avatorImage = [UIImage imageNamed:imageNameWithBundlePath];
    if (!avatorURL) {
        self.avatorImageView.image = avatorImage;
    } else {
        [self.avatorImageView sd_setImageWithURL:avatorURL placeholderImage:avatorImage];
    }
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;
    if (subtitle.length == 0) {
        [self.subtitleLabel removeFromSuperview];
    }
}

@end
