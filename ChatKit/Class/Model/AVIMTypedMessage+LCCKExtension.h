//
//  AVIMTypedMessage+LCCKExtension.h
//  ChatKit
//
// v0.5.2 Created by 陈宜龙 on 16/5/26.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <AVOSCloudIM/AVOSCloudIM.h>
@class LCCKMessage;

@interface AVIMTypedMessage (LCCKExtension)

- (BOOL)lcck_isSupportThisCustomMessage;

+ (AVIMTypedMessage *)lcck_messageWithLCCKMessage:(LCCKMessage *)message;
- (void)lcck_setObject:(id)object forKey:(NSString *)key;

@end
