//
//  LCCKBubbleImageFactory.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKChatUntiles.h"
@import UIKit;

@interface LCCKBubbleImageFactory : NSObject

+ (UIImage *)bubbleImageViewForType:(LCCKMessageOwner)owner messageType:(LCCKMessageType)messageType isHighlighted:(BOOL)isHighlighted;

@end
