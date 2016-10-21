//
//  LCCKMessageVoiceFactory.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/21.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKConstants.h"
@import UIKit;

@interface LCCKMessageVoiceFactory : NSObject

+ (UIImageView *)messageVoiceAnimationImageViewWithBubbleMessageType:(LCCKMessageOwnerType)owner;

@end
