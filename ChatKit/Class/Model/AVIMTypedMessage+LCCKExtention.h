//
//  AVIMTypedMessage+LCCKExtention.h
//  ChatKit
//
//  Created by 陈宜龙 on 16/5/26.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <AVOSCloudIM/AVOSCloudIM.h>
@class LCCKMessage;

@interface AVIMTypedMessage (LCCKExtention)

+ (AVIMTypedMessage *)lcck_messageWithLCCKMessage:(LCCKMessage *)message;

@end
