//
//  LCCKBubbleImageFactory.h
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/21.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCCKConstants.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

@interface LCCKBubbleImageFactory : NSObject

+ (UIImage *)bubbleImageViewForType:(LCCKMessageOwnerType)owner
                        messageType:(AVIMMessageMediaType)messageMediaType
                      isHighlighted:(BOOL)isHighlighted;
@end
