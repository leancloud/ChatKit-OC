//
//  LCIMBubbleImageFactory.h
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCIMChatUntiles.h"
@import UIKit;

@interface LCIMBubbleImageFactory : NSObject

+ (UIImage *)bubbleImageViewForType:(LCIMMessageOwner)owner isHighlighted:(BOOL)isHighlighted;

@end
