//
//  LCCKBubbleImageFactory.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/21.
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
