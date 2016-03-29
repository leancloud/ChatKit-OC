//
//  LCIMMessageVoiceFactory.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCIMMessageVoiceFactory.h"

@implementation LCIMMessageVoiceFactory

+ (UIImageView *)messageVoiceAnimationImageViewWithBubbleMessageType:(LCIMMessageOwner)owner {
    UIImageView *messageVoiceAniamtionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    NSString *imageSepatorName;
    switch (owner) {
        case LCIMMessageOwnerSelf:
            imageSepatorName = @"Sender";
            break;
        case LCIMMessageOwnerOther:
            imageSepatorName = @"Receiver";
            break;
        default:
            break;
    }
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:4];
    NSString *imagePrefix = imageSepatorName;
    for (NSInteger i = 0; i < 4; i ++) {
        NSString *imageName = [imagePrefix stringByAppendingFormat:@"VoiceNodePlaying00%ld", (long)i];
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"VoiceMessageSource.bundle/%@", imageName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        if (image)
            [images addObject:image];
    }
    
    messageVoiceAniamtionImageView.image = ({
        NSString *imageName = [imagePrefix stringByAppendingString:@"VoiceNodePlaying"];
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"VoiceMessageSource.bundle/%@", imageName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        image;});
    messageVoiceAniamtionImageView.animationImages = images;
    messageVoiceAniamtionImageView.animationDuration = 1.0;
    [messageVoiceAniamtionImageView stopAnimating];
    
    return messageVoiceAniamtionImageView;
}

@end
