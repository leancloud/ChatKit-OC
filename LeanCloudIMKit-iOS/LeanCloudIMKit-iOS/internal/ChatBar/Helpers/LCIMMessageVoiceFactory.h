//
//  LCIMMessageVoiceFactory.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMChatUntiles.h"
@import UIKit;

@interface LCIMMessageVoiceFactory : NSObject

+ (UIImageView *)messageVoiceAnimationImageViewWithBubbleMessageType:(LCIMMessageOwner)owner;

@end
