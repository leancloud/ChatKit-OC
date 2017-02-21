//
//  LCCKVCardView.m
//  ChatKit-OC
//
//  v0.8.5 Created by ElonChan on 16/8/15.
//  Copyright © 2016年 ElonChan . All rights reserved.
//

#import "LCCKVCardView.h"
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@interface LCCKVCardView()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (nonatomic, copy) NSString *clientId;

@end

@implementation LCCKVCardView

+ (id)vCardView {
    return [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil][0];
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    [self.nameLabel sizeToFit];
    LCCKAvatarImageViewCornerRadiusBlock avatarImageViewCornerRadiusBlock = [LCChatKit sharedInstance].avatarImageViewCornerRadiusBlock;
    if (avatarImageViewCornerRadiusBlock) {
        CGFloat avatarImageViewCornerRadius = avatarImageViewCornerRadiusBlock(self.avatarView.frame.size);
        self.avatarView.lcck_cornerRadius = avatarImageViewCornerRadius;
    }
    UITapGestureRecognizer *tapGestureRecognizer =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(vCardClicked)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (void)vCardClicked {
    !self.vCardDidClickedHandler ?: self.vCardDidClickedHandler(self.clientId);
}

- (void)configureWithAvatarURL:(NSURL *)avatarURL title:(NSString *)title clientId:(NSString *)clientId {
    NSString *imageName = @"Placeholder_Avatar";
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"Placeholder" bundleForClass:[LCChatKit class]];
    UIImage *avatarImage = image;
    [self.avatarView sd_setImageWithURL:avatarURL placeholderImage:avatarImage];
    self.nameLabel.text = title;
    self.clientId = clientId;
}

@end
