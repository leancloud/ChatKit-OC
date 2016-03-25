//
//  LCIMMessageVoiceFactory.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 EloncChan. All rights reserved.
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
    for (NSInteger i = 0; i < 4; i ++) {
        [imageSepatorName stringByAppendingFormat:@"VoiceNodePlaying00%ld", (long)i];
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"VoiceMessageSource.bundle/%@", imageSepatorName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        if (image)
            [images addObject:image];
    }
    
    messageVoiceAniamtionImageView.image = ({
        [imageSepatorName stringByAppendingString:@"VoiceNodePlaying"];
        NSString *imageNameWithBundlePath = [NSString stringWithFormat:@"VoiceMessageSource.bundle/%@", imageSepatorName];
        UIImage *image = [UIImage imageNamed:imageNameWithBundlePath];
        image;});
    messageVoiceAniamtionImageView.animationImages = images;
    messageVoiceAniamtionImageView.animationDuration = 1.0;
    [messageVoiceAniamtionImageView stopAnimating];
    
    return messageVoiceAniamtionImageView;
}

@end
