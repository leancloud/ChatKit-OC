//
//  LCCKMessageVoiceFactory.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  v0.5.0 Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKConstants.h"
@import UIKit;

@interface LCCKMessageVoiceFactory : NSObject

+ (UIImageView *)messageVoiceAnimationImageViewWithBubbleMessageType:(LCCKMessageOwnerType)owner;

@end
